import base64, json, io, os, subprocess, sys

ROOT = r"E:\Dennis\GamePadDex复刻"
REPO = "denniswung/GamePadDex"
TMP = os.path.join(os.environ["TEMP"], "put_sync.json")


def sh(args):
    r = subprocess.run(args, capture_output=True)
    return r.returncode, r.stdout.decode("utf-8", "replace")


code, out = sh(["git", "-C", ROOT, "-c", "core.quotepath=false",
                "diff", "--name-status", "origin/main..HEAD"])
if code != 0:
    print("diff failed")
    sys.exit(1)
entries = []
for line in out.splitlines():
    parts = line.split("\t")
    if len(parts) < 2:
        continue
    st, path = parts[0], parts[1]
    entries.append((st, path))
print("files:", len(entries))

ok = fail = 0
for st, path in entries:
    api = f"repos/{REPO}/contents/{path}"
    # 取远端 sha（新文件没有）
    c, sha_out = sh(["gh", "api", api, "--jq", ".sha"])
    sha = sha_out.strip() if c == 0 and sha_out.strip() else None
    if st == "D":
        if not sha:
            continue
        payload = {"message": f"v1.58: 删除 {path}", "sha": sha, "branch": "main"}
        io.open(TMP, "w", encoding="utf-8", newline="\n").write(json.dumps(payload))
        c2, o2 = sh(["gh", "api", "-X", "DELETE", api, "--input", TMP])
        print(("DEL OK  " if c2 == 0 else "DEL FAIL"), path)
        ok += c2 == 0
        fail += c2 != 0
        continue
    local = os.path.join(ROOT, path.replace("/", os.sep))
    if not os.path.exists(local):
        print("SKIP missing", path)
        continue
    data = io.open(local, "rb").read()
    payload = {
        "message": "v1.58: 精简映射列表 / 修复目标应用选择 / 代码审计修复",
        "content": base64.b64encode(data).decode("ascii"),
        "branch": "main",
    }
    if sha:
        payload["sha"] = sha
    io.open(TMP, "w", encoding="utf-8", newline="\n").write(json.dumps(payload, ensure_ascii=False))
    c3, o3 = sh(["gh", "api", "-X", "PUT", api, "--input", TMP])
    if c3 == 0:
        ok += 1
        print("PUT OK  ", path)
    else:
        fail += 1
        print("PUT FAIL", path, o3[:160].replace("\n", " "))
print(f"done ok={ok} fail={fail}")
