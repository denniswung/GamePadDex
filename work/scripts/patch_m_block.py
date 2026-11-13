import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 3
# wait until the helper reports the launcher as foreground (per-app profile)
i=0
while [ $i -lt 4 ]; do
    grep 'TOP ' /data/adb/gpm/helper.log | tail -1 | grep -q 'app.lawnchair' && break
    sleep 1
    i=$((i+1))
done
screencap -p /sdcard/m1.png
M1=$(ls -l /sdcard/m1.png | awk '{print $5}')'''
new = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 3
# wait until the helper reports the *HOME* app as foreground (any launcher)
HOMEPKG=$(grep '^HOME ' /data/adb/gpm/helper.log | tail -1 | awk '{print $2}')
i=0
while [ $i -lt 5 ]; do
    if [ -n "$HOMEPKG" ] && grep 'TOP ' /data/adb/gpm/helper.log | tail -1 | grep -q "$HOMEPKG"; then break; fi
    sleep 1
    i=$((i+1))
done
M0=$(wc -l < /data/adb/gpm/helper.log)
screencap -p /sdcard/m1.png
M1=$(ls -l /sdcard/m1.png | awk '{print $5}')'''
assert old in src
src = src.replace(old, new, 1)

old2 = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 1
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1'''
new2 = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 2
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1'''
assert old2 in src
src = src.replace(old2, new2, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
