import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 3
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1'''
new = '''# a fullscreen launcher may swallow the shade gesture: test it in Settings
am force-stop com.android.settings >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1'''
assert old in src
src = src.replace(old, new, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
