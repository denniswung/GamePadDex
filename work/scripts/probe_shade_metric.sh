#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
screencap -p /data/local/tmp/s0.png 2>/dev/null
echo "screenshot size now: $(wc -c < /data/local/tmp/s0.png)"
input keyevent 4 >/dev/null 2>&1; sleep 1
dumpsys window 2>/dev/null > /data/local/tmp/w0.txt
$VG key 314 150 1200 >/dev/null 2>&1
sleep 2
dumpsys window 2>/dev/null > /data/local/tmp/w1.txt
echo "=== dumpsys window 差异（前 25 行）==="
diff /data/local/tmp/w0.txt /data/local/tmp/w1.txt 2>/dev/null | head -25
echo "=== 状态栏/面板关键字 ==="
grep -m3 -E 'mExpandedPanel|NotificationShade' /data/local/tmp/w1.txt | head -3
