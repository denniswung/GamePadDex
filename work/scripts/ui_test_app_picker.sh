#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop $PKG; sleep 0.5
am start -n $PKG/.ButtonDetailActivity --es button r3 >/dev/null 2>&1
sleep 2

echo "1) 点「当前动作」行 (1280,512)"
input tap 1280 512 >/dev/null 2>&1
sleep 1.5
screencap -p /data/local/tmp/p1.png 2>/dev/null

echo "2) 动作列表：DPAD 向下 17 次（首项需要先按一次聚焦）到索引16「打开目标应用」"
for i in $(seq 1 17); do input keyevent 20 >/dev/null 2>&1; sleep 0.06; done
sleep 0.2
input keyevent 23 >/dev/null 2>&1
sleep 1.8
screencap -p /data/local/tmp/p2.png 2>/dev/null
echo "   动作: $(grep -oE 'name="btn_r3" value="[^"]*"' "$XML" 2>/dev/null || echo '(无)')"

echo "3) 应用列表：选第一个"
input keyevent 20 >/dev/null 2>&1
sleep 0.2
input keyevent 23 >/dev/null 2>&1
sleep 1.8
screencap -p /data/local/tmp/p3.png 2>/dev/null
echo "   btn_r3: $(grep -oE 'name="btn_r3" value="[^"]*"' "$XML" 2>/dev/null || echo '(无)')"
echo "   par_r3: $(grep -oE 'name="par_r3" value="[^"]*"' "$XML" 2>/dev/null || echo '(无)')"
