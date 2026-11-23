"""Push the local v1.66 commit to GitHub through the REST API (git protocol to
github.com:443 is blocked in this environment; api.github.com works via gh).

Strategy: Git Data API.
  1. read remote main head + its tree
  2. for every path that differs between remote head and local HEAD, upload the
     *git blob content* (git cat-file blob <sha>, i.e. LF-normalised bytes, NOT the
     CRLF worktree bytes) and build a new tree on top of the remote tree
  3. create a commit whose parent is the remote head, then fast-forward the ref
  4. verify the resulting remote tree sha == local `git show -s --format=%T HEAD`
"""
import base64
import json
import os
import subprocess
import sys
import tempfile

ROOT = r"E:\Dennis\GamePadDex复刻"
REPO = "denniswung/GamePadDex"


def run(args, cwd=ROOT):
    p = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError("%s failed: %s" % (args, p.stderr.decode("utf-8", "replace")[:400]))
    return p.stdout


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
    return out.decode("utf-8", "replace").strip()


def main():
    remote_head = gh(["repos/%s/git/ref/heads/main" % REPO, "--jq", ".object.sha"])
    remote_tree = gh(["repos/%s/git/commits/%s" % (REPO, remote_head), "--jq", ".tree.sha"])
    local_tree = run(["git", "show", "-s", "--format=%T", "HEAD"]).decode().strip()
    print("remote_head=%s\nremote_tree=%s\nlocal_tree=%s" % (remote_head, remote_tree, local_tree))

    raw = run(["git", "-c", "core.quotepath=false", "diff", "--no-abbrev", "--raw", "-z",
               "%s..HEAD" % remote_head])
    fields = raw.split(b"\x00")
    entries = []
    i = 0
    changed = []
    while i < len(fields):
        meta = fields[i].decode("utf-8", "replace")
        if not meta.startswith(":"):
            i += 1
            continue
        parts = meta[1:].split(" ")
        new_mode, new_sha, status = parts[1], parts[3], parts[4][0]
        path = fields[i + 1].decode("utf-8")
        changed.append((status, path, new_mode, new_sha))
        i += 2
    print("changed files=%d" % len(changed))

    for status, path, mode, sha in changed:
        if status == "D":
            entries.append({"path": path, "mode": mode, "type": "blob", "sha": None})
            print("DEL", path)
            continue
        content = run(["git", "cat-file", "blob", sha])
        b64 = base64.b64encode(content).decode("ascii")
        uploaded = gh(["-X", "POST", "repos/%s/git/blobs" % REPO, "--jq", ".sha"],
                      {"content": b64, "encoding": "base64"})
        if uploaded != sha:
            print("  warn: blob sha mismatch for %s (%s vs %s)" % (path, uploaded, sha))
        entries.append({"path": path, "mode": mode, "type": "blob", "sha": uploaded})
        print("PUT", path, len(content), "B")

    tree_sha = gh(["-X", "POST", "repos/%s/git/trees" % REPO, "--jq", ".sha"],
                  {"base_tree": remote_tree, "tree": entries})
    print("new_tree=%s" % tree_sha)

    message = run(["git", "log", "-1", "--format=%B"]).decode("utf-8").strip()
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
