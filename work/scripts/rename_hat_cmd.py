import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
old = "        case 'H': {\n            /* H <dir> [hold]"
new = "        case 'A': {\n            /* A <dir> [hold]"
if old in s:
    s = s.replace(old, new, 1)
    io.open(h, "w", encoding="utf-8", newline="\n").write(s)
    print("c renamed")
else:
    print("c MISS")

r = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
t = io.open(r, encoding="utf-8").read()
old2 = 'fun hat(dir: Int, hold: Boolean = false) = send("H $dir "'
new2 = 'fun hat(dir: Int, hold: Boolean = false) = send("A $dir "'
if old2 in t:
    t = t.replace(old2, new2, 1)
    io.open(r, "w", encoding="utf-8", newline="\n").write(t)
    print("kt renamed")
else:
    print("kt MISS")
