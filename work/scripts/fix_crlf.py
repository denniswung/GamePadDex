import io, glob
for p in glob.glob("/mnt/e/Dennis/GamePadDex复刻/work/scripts/*.sh"):
    s = io.open(p, encoding="utf-8", errors="replace").read()
    if "\r\n" in s:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s.replace("\r\n", "\n"))
        print("lf", p.split("/")[-1])
print("done")
