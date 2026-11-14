#!/system/bin/sh
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
input keyevent 4 >/dev/null 2>&1; sleep 1
screencap -p /data/local/tmp/t0.png 2>/dev/null
echo "base: $(wc -c < /data/local/tmp/t0.png)"
: > /data/adb/gpm/helper.log
$VG key 314 200 1500 >/dev/null 2>&1
sleep 2
screencap -p /data/local/tmp/t1.png 2>/dev/null
echo "after1: $(wc -c < /data/local/tmp/t1.png)  helper: $(grep -a 'NOTIF' /data/adb/gpm/helper.log | tail -1)"
$VG key 314 200 1500 >/dev/null 2>&1
sleep 2
screencap -p /data/local/tmp/t2.png 2>/dev/null
echo "after2: $(wc -c < /data/local/tmp/t2.png)"
