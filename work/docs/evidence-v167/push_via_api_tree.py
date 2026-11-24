"""Push local HEAD to GitHub through the REST API by *tree comparison*.

Why not commit range: the local branch history and the API-created remote history
share content but not commit objects (the API commits were built by hand), so
`git diff <remote>..HEAD` can fail when the remote commit object is not local.

This script instead:
  1. reads the remote main head + its recursive tree
  2. lists the local HEAD tree (git ls-tree -r -z)
  3. uploads only the blobs whose content differs (git cat-file blob bytes, LF-normalised)
     and builds a new tree on top of the remote tree (deleted paths -> sha null)
  4. creates a commit whose parent is the remote head, fast-forwards main
  5. verifies the resulting remote tree sha == local HEAD tree sha
"""
import base64
import json
import os
import subprocess
import sys
import tempfile

ROOT = r"E:\Dennis\GamePadDex复刻"
REPO = "denniswung/GamePadDex"


def run(args, cwd=ROOT, binary=False):
    p = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError("%s failed: %s" % (args, p.stderr.decode("utf-8", "replace")[:500]))
    return p.stdout if binary else p.stdout.decode("utf-8", "replace")


def gh(args, payload=None):
    cmd = ["gh", "api"] + args
    tmp = None
    if payload is not None:
        fd, tmp = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            json.dump(payload, f, ensure_ascii=False)
        cmd += ["--input", tmp]
    try:
        out = run(cmd)
    finally:
        if tmp and os.path.exists(tmp):
            os.remove(tmp)
    return out.strip()


def remote_tree_entries(tree_sha):
    raw = run(["gh", "api", "repos/%s/git/trees/%s?recursive=1" % (REPO, tree_sha)])
    data = json.loads(raw)
    if data.get("truncated"):
        raise RuntimeError("remote tree listing truncated")
    out = {}
    for e in data["tree"]:
        if e["type"] == "blob":
            out[e["path"]] = (e["mode"], e["sha"])
    return out


def local_tree_entries():
    raw = run(["git", "ls-tree", "-r", "-z", "HEAD"], binary=True)
    out = {}
    for rec in raw.split(b"\x00"):
        if not rec:
            continue
        meta, path = rec.split(b"\t", 1)
        mode, typ, sha = meta.decode().split(" ")
        out[path.decode("utf-8")] = (mode, sha)
    return out


def main():
    remote_head = gh(["repos/%s/git/ref/heads/main" % REPO, "--jq", ".object.sha"])
    remote_tree = gh(["repos/%s/git/commits/%s" % (REPO, remote_head), "--jq", ".tree.sha"])
    local_tree = run(["git", "show", "-s", "--format=%T", "HEAD"]).strip()
    print("remote_head=%s\nremote_tree=%s\nlocal_tree=%s" % (remote_head, remote_tree, local_tree))
    if remote_tree == local_tree:
        print("already up to date (tree match)"); return 0

    rem = remote_tree_entries(remote_tree)
    loc = local_tree_entries()
    print("remote blobs=%d local blobs=%d" % (len(rem), len(loc)))

    changed = [(p, m, s) for p, (m, s) in loc.items() if rem.get(p) != (m, s)]
    deleted = [p for p in rem if p not in loc]
    print("changed=%d deleted=%d" % (len(changed), len(deleted)))

    entries = []
    for path, mode, sha in changed:
        content = run(["git", "cat-file", "blob", sha], binary=True)
        uploaded = gh(["-X", "POST", "repos/%s/git/blobs" % REPO, "--jq", ".sha"],
                      {"content": base64.b64encode(content).decode("ascii"), "encoding": "base64"})
        if uploaded != sha:
            print("  warn: sha mismatch %s (%s != %s)" % (path, uploaded, sha))
        entries.append({"path": path, "mode": mode, "type": "blob", "sha": uploaded})
        print("PUT", path, len(content), "B")
    for path in deleted:
        mode = rem[path][0]
        entries.append({"path": path, "mode": mode, "type": "blob", "sha": None})
        print("DEL", path)

    tree_sha = gh(["-X", "POST", "repos/%s/git/trees" % REPO, "--jq", ".sha"],
                  {"base_tree": remote_tree, "tree": entries})
    print("new_tree=%s" % tree_sha)
    message = run(["git", "log", "-1", "--format=%B"]).strip()
    commit_sha = gh(["-X", "POST", "repos/%s/git/commits" % REPO, "--jq", ".sha"],
                    {"message": message, "tree": tree_sha, "parents": [remote_head]})
    print("new_commit=%s" % commit_sha)
    ref = gh(["-X", "PATCH", "repos/%s/git/refs/heads/main" % REPO, "--jq", ".object.sha"],
             {"sha": commit_sha, "force": False})
    print("ref_now=%s" % ref)
    verify_tree = gh(["repos/%s/git/commits/%s" % (REPO, ref), "--jq", ".tree.sha"])
    print("remote_commit_tree=%s" % verify_tree)
    ok = verify_tree == local_tree
    print("TREE MATCH" if ok else "TREE MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
