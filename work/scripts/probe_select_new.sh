#!/system/bin/sh
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
input keyevent 4 >/dev/null 2>&1; sleep 1
screencap -p /data/local/tmp/z0.png 2>/dev/null
echo "base=$(wc -c < /data/local/tmp/z0.png)"
: > /data/adb/gpm/helper.log
$VG key 314 200 1500 >/dev/null 2>&1
sleep 2.5
screencap -p /data/local/tmp/z1.png 2>/dev/null
echo "after=$(wc -c < /data/local/tmp/z1.png)"
echo "helper: $(grep -a NOTIF /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
