#!/system/bin/sh
# 验证：空闲隐藏指针后，按 L3 能恢复指针并一次居中
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
md(){ grep -c 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5

echo "1) 先推摇杆让指针存在: mice=$(md)"
$VG stick 0 20000 250 2000 >/dev/null 2>&1
sleep 0.8
echo "   after stick mice=$(md)"

echo "2) 等 10 秒让它自动隐藏"
sleep 10
echo "   after idle mice=$(md)"

echo "3) 直接按 L3（应恢复指针并居中）"
logcat -c
$VG key 317 100 2000 >/dev/null 2>&1
sleep 1.2
echo "   after L3 mice=$(md)"
echo "   助手: $(grep -aE 'POINTER on|CENTER' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "   应用看到的指针坐标:"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -3 | sed 's/.*PROBE//;s/^.*I PadProbe: /     /'

echo "4) 再按两次 L3，坐标应一致"
for i in 1 2; do
  $VG stick 0 20000 200 0 >/dev/null 2>&1
  sleep 0.2
  $VG key 317 100 1200 >/dev/null 2>&1
  sleep 0.9
done
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -3 | sed 's/^.*PadProbe: /     /'
