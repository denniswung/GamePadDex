#!/system/bin/sh
VG=/data/local/tmp/vgpad
top() { dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 \([^ /]*\).*/\1/'; }
home_ok() { case "$1" in *launcher*|*home*) echo yes;; *) echo no;; esac; }

echo "当前 top=$(top)"
for d in 0 100 200 400 800; do
    am start -n com.android.settings/.Settings >/dev/null 2>&1
    sleep $(echo "scale=2; $d/1000" | bc 2>/dev/null || echo 0.$d)
    logcat -c
    L=$(wc -l < /data/adb/gpm/helper.log)
    $VG key 308 120 0 >/dev/null 2>&1
    sleep 1.6
    KEYON=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')
    T=$(top)
    echo "delay=${d}ms KEYON=$KEYON top=$T home=$(home_ok "$T")"
    # 回到 launcher 再试下一轮
    input keyevent KEYCODE_HOME >/dev/null 2>&1
    sleep 1.2
done
