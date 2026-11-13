#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n $PAD/.ui.KeyTestActivity >/dev/null 2>&1
sleep 1.5

echo "=== 1) 单独方向键：应经虚拟手柄 HAT 到达应用 ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG hat 0 1 150 2000 >/dev/null 2>&1
sleep 1.0
echo "   HAT: $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'HAT ')"
echo "   应用收到: $(logcat -d -s PadProbe | grep -o 'DPAD_UP([0-9]*)' | head -1)"
logcat -d -s DexPad | grep -E 'arrow key|button up' | sed 's/^.*DexPad  : /     /' | head -2

echo "=== 2) X + ↑：组合优先（音量+），不应变成方向键 ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG hold 307 1200 2000 >/dev/null 2>&1 & )
sleep 2.1
$VG hat 0 1 150 0 >/dev/null 2>&1
sleep 1.0
echo "   mix: $(logcat -d -s DexPad | grep -c 'mix 0 x+up')  KEYON24: $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 24')"
logcat -d -s DexPad | grep -E 'mix 0|volume up' | sed 's/^.*DexPad  : /     /' | head -2

echo "=== 3) 先方向键、后按 X（顺序反过来）不吃组合，仍是方向键 ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG hold 307 900 2200 >/dev/null 2>&1 & )
$VG hat 0 -1 700 2000 >/dev/null 2>&1
sleep 1.2
echo "   arrow: $(logcat -d -s DexPad | grep -c 'arrow key')  mix1: $(logcat -d -s DexPad | grep -c 'mix 1')"

echo "=== 4) 方向键连按 4 次（上下左右）==="
for h in "0 1" "0 -1" "-1 0" "1 0"; do
  $VG hat $h 120 1500 >/dev/null 2>&1
  sleep 0.5
done
echo "   HAT 脉冲数: $(grep -ac 'HAT ' /data/adb/gpm/helper.log)  应用 DPAD 计数: $(logcat -d -s PadProbe | grep -c 'KEYCODE_DPAD')"
