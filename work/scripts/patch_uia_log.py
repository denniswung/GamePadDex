import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
old = '    system("/system/bin/uiautomator dump --compressed " FOCUS_UI " >/dev/null 2>&1");'
new = '    system("/system/bin/uiautomator dump --compressed " FOCUS_UI " >/data/adb/gpm/uia.log 2>&1");'
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
