import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
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
M1=$(ls -l /sdcard/m1.png | awk '{print $5}')
/data/local/tmp/vgpad stick 4 20000 700 2000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/m2.png
M2=$(ls -l /sdcard/m2.png | awk '{print $5}')
MSW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep -c 'SWIPE ')
DIFF=$(expr "$M1" - "$M2" | tr -d -)
if [ "$MSW" -ge 1 ] && [ "$DIFF" -gt $((M1 / 50)) ]; then
    ok "M1 launcher swipe ($M1 -> $M2, swipes=$MSW)"
else
    bad "M1 launcher swipe ($M1 -> $M2, swipes=$MSW)"
fi'''

new = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 2
HOMEPKG=$(grep '^HOME ' /data/adb/gpm/helper.log | tail -1 | awk '{print $2}')
M0=$(wc -l < /data/adb/gpm/helper.log)
# wait until a *new* TOP line names the HOME app (the old line may be stale)
i=0
while [ $i -lt 6 ]; do
    if [ -n "$HOMEPKG" ] && tail -n +$((M0 + 1)) /data/adb/gpm/helper.log | grep 'TOP ' | tail -1 | grep -q "$HOMEPKG"; then break; fi
    sleep 1
    i=$((i+1))
done
screencap -p /sdcard/m1.png
M1=$(ls -l /sdcard/m1.png | awk '{print $5}')
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 700 2000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/m2.png
M2=$(ls -l /sdcard/m2.png | awk '{print $5}')
SW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep 'SWIPE ' | head -1)
SY1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\\1/p')
SY2=$(echo "$SW" | sed -n 's/.*-> [0-9]*,\([0-9]*\).*/\\1/p')
if [ -n "$SY1" ] && [ "$SY1" -ge 1200 ] && [ "$SY2" -lt "$SY1" ]; then
    ok "M1 launcher bottom-anchored swipe ($SW)"
else
    bad "M1 launcher bottom-anchored swipe ($SW)"
fi'''

assert old in src
src = src.replace(old, new, 1)

old2 = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 2
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/m3.png
M3=$(ls -l /sdcard/m3.png | awk '{print $5}')
if [ "$M3" -gt 2000000 ]; then
    ok "M2 notification shade ($M3)"
else
    bad "M2 notification shade ($M3)"
fi'''

new2 = '''input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 3
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/m3.png
M3=$(ls -l /sdcard/m3.png | awk '{print $5}')
SW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep 'SWIPE ' | head -1)
SY1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\\1/p')
SY2=$(echo "$SW" | sed -n 's/.*-> [0-9]*,\([0-9]*\).*/\\1/p')
if [ -n "$SY1" ] && [ "$SY1" -le 400 ] && [ "$SY2" -gt "$SY1" ] && [ "$M3" -gt 1800000 ]; then
    ok "M2 notification shade ($SW, $M3)"
else
    bad "M2 notification shade ($SW, $M3)"
fi'''

assert old2 in src
src = src.replace(old2, new2, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
