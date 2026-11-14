#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ProbeActivity >/dev/null 2>&1 || am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2

echo "=== 触摸设备是否存在 ==="
grep -E 'N: Name=' /proc/bus/input/devices | grep -i 'touch panel' || echo "  (还没有：懒创建)"

echo "=== 设置触摸面尺寸 j 2560 1600 ==="
: > /data/adb/gpm/helper.log
hcmd "j 2560 1600"; sleep 1
grep -a 'TOUCH_SIZE' /data/adb/gpm/helper.log | tail -1

echo "=== 单指点击 k 1280 800 ==="
logcat -c
hcmd "k 1280 800 1"; sleep 0.35
hcmd "k 1280 800 0"; sleep 0.8
grep -aE 'TOUCH (down|up)' /data/adb/gpm/helper.log | tail -3
echo "--- 应用收到的触摸事件 ---"
logcat -d -s PadProbe | grep -iE 'touch-(down|up)' | tail -4 | sed 's/^.*PadProbe: /  /'
echo "--- 触摸设备 ---"
grep -E 'N: Name=' /proc/bus/input/devices | grep -i 'touch panel' || echo "  无"

echo "=== 双指缩放 l 1（1.2 秒后停止） ==="
logcat -c
hcmd "l 1 1280 800"; sleep 1.2; hcmd "l 0 0 0"; sleep 0.5
grep -aE 'PINCH' /data/adb/gpm/helper.log | tail -3
echo "--- 应用收到的触摸事件（应有大量 move）---"
logcat -d -s PadProbe | grep -icE 'touch' 
logcat -d -s PadProbe | grep -iE 'touch' | tail -4 | sed 's/^.*PadProbe: /  /'
