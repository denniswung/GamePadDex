#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3

rm -f /data/adb/gpm/taskbounds.txt
: > /data/adb/gpm/helper.log
echo "=== 第一次滑动（缓存冷启动）==="
$VG stick 4 20000 900 2000 >/dev/null 2>&1
sleep 1.2
grep -a 'SWIPE' /data/adb/gpm/helper.log | head -3
echo "--- 边界缓存文件 ---"
cat /data/adb/gpm/taskbounds.txt 2>/dev/null || echo "(还没写出来)"

echo
echo "=== 第二次滑动（缓存命中）==="
: > /data/adb/gpm/helper.log
$VG stick 4 -20000 900 0 >/dev/null 2>&1
sleep 1.2
grep -a 'SWIPE' /data/adb/gpm/helper.log | head -3

echo
echo "=== 光标锚定：先移动光标，再按 RB 滑动 ==="
$VG stick 0 8000 400 2000 >/dev/null 2>&1
sleep 0.4
: > /data/adb/gpm/helper.log
$VG key 311 120 900 >/dev/null 2>&1
sleep 1.2
grep -a 'SWIPE' /data/adb/gpm/helper.log | head -2

echo
echo "=== prep 时间统计（毫秒）==="
grep -a 'prep=' /data/adb/gpm/helper.log | sed -n 's/.*prep=\([0-9]*\)us/\1/p' | head -5
