import base64, json, io, subprocess, sys, os
root = r"E:\Dennis\GamePadDex复刻"
path = os.path.join(root, "README.md")
sha = subprocess.check_output(["gh", "api", "repos/denniswung/GamePadDex/contents/README.md", "--jq", ".sha"], text=True).strip()
data = io.open(path, "rb").read()
payload = {
    "message": "docs: README 顶部加 Releases 下载链接",
    "content": base64.b64encode(data).decode("ascii"),
    "sha": sha,
    "branch": "main",
}
out = os.path.join(os.environ["TEMP"], "readme-put.json")
io.open(out, "w", encoding="utf-8", newline="\n").write(json.dumps(payload, ensure_ascii=False))
print("sha:", sha, "bytes:", len(data))
