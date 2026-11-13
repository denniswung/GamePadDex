#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad

am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

echo "=== 1) 只按 Y ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.3
echo "   home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3') power=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'POWER')"
echo "   $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"

echo "=== 2) Y+L3 仍然可用（真按组合）==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG combo 308 317 400 2000 >/dev/null 2>&1
sleep 1.4
echo "   power=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'POWER') home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'mix 9|power key' | sed 's/^.*DexPad  : /     /' | head -3
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; sleep 1

echo "=== 3) LB / RB 方向（RB 应为手指上滑 = 内容下滑）==="
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.2
for k in 310 311; do
  logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
  $VG key $k 400 2000 >/dev/null 2>&1
  sleep 1.0
  echo "   key=$k $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -m1 'SWIPE')"
  logcat -d -s DexPad | grep -E 'scroll_swipe_(up|down) started' | sed 's/^.*DexPad  : /     /'
done

echo "=== 4) 松杆后是否还滑 ==="
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.5
logcat -c
$VG stick 0 20000 500 2000 >/dev/null 2>&1
sleep 1.0
echo "   松手后 1s 内的 ptr move 记录（应为 0 或全 0）："
logcat -d -s DexPad | grep 'ptr move' | tail -4 | sed 's/^.*DexPad  : /     /'
