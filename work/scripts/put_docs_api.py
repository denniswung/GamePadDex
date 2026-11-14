import base64, json, io, subprocess, os, sys

root = r"E:\Dennis\GamePadDex复刻"
files = ["README.md", "release/RELEASE-NOTES.md"]
tmp = os.path.join(os.environ["TEMP"], "put.json")

for rel in files:
    local = os.path.join(root, rel.replace("/", os.sep))
    data = io.open(local, "rb").read()
    sha = subprocess.check_output(
        ["gh", "api", f"repos/denniswung/GamePadDex/contents/{rel}", "--jq", ".sha"],
        text=True).strip()
    payload = {
        "message": "docs: v1.55 说明（左键默认鼠标事件）",
        "content": base64.b64encode(data).decode("ascii"),
        "sha": sha,
        "branch": "main",
    }
    io.open(tmp, "w", encoding="utf-8", newline="\n").write(json.dumps(payload, ensure_ascii=False))
    r = subprocess.run(["gh", "api", "-X", "PUT", f"repos/denniswung/GamePadDex/contents/{rel}",
                        "--input", tmp], capture_output=True, text=True)
    ok = r.returncode == 0
    print(f"{rel}: {'OK' if ok else 'FAIL'} sha={sha[:8]} bytes={len(data)}")
    if not ok:
        print(r.stderr[:300])
