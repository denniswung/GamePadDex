#!/system/bin/sh
VG=/data/local/tmp/vgpad
PKG=com.dennis.dexpad
PAD=com.dennis.padtest

echo "=== 1) 只按 Y：看是否触发电源/锁屏 ==="
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.2
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.4
echo "  POWER=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'POWER')  HOME=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'button y|single|mix|power|home' | sed 's/^.*DexPad  : /  /'
echo "  screen=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
sleep 1

echo "=== 2) LB / RB 各自的实际滚动方向（看 SWIPE 起点→终点） ==="
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 1.5
for k in 310 311; do
  logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
  $VG key $k 400 2000 >/dev/null 2>&1
  sleep 1.0
  echo "  key=$k: $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -m1 'SWIPE')"
  logcat -d -s DexPad | grep -E 'wheel scroll_swipe_(up|down) started' | sed 's/^.*DexPad  : /    /'
done

echo "=== 3) 松杆后是否还在滑（记录松手后 600ms 的 hover 变化） ==="
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5
$VG stick 0 20000 500 2000 >/dev/null 2>&1
sleep 0.2
A=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9]*\) y=\([0-9]*\).*/\1,\2/p')
sleep 0.7
B=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9]*\) y=\([0-9]*\).*/\1,\2/p')
echo "  after-release A=$A B=$B"
logcat -d -s DexPad | grep 'ptr move' | tail -6 | sed 's/^.*DexPad  : /    /'
