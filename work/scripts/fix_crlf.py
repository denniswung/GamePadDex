import io, glob, os

# 把 work/scripts/*.sh 统一成 LF（设备端 sh 不能吃 CRLF）。
# 路径用脚本自身位置推导，避免仓库目录名（含中文）在不同挂载/编码下失配。
here = os.path.dirname(os.path.abspath(__file__))
for p in sorted(glob.glob(os.path.join(here, "*.sh"))):
    s = io.open(p, encoding="utf-8", errors="replace").read()
    if "\r\n" in s:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.replace("\r\n", "\n"))
        print("lf", os.path.basename(p))
print("done")
