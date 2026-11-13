#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
SOCK=/data/data/$PKG/files/gpm.sock

am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3

echo "=== 1) 桌面上按 LB / RB：应该发方向键，不发滑动 ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 1.5
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 \([^ /]*\).*/\1/')
echo "   当前前台: $TOP"
for k in 310 311; do
  logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
  $VG key $k 400 2000 >/dev/null 2>&1
  sleep 1.0
  SW=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'SWIPE')
  AR=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'ARROW')
  KEY=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -cE 'KEYON 0 (19|20)')
  echo "   key=$k  SWIPE=$SW ARROW=$AR KEYON_方向=$KEY"
  logcat -d -s DexPad | grep -E 'launcher foreground|arrow key' | sed 's/^.*DexPad  : /     /' | head -2
done

echo "=== 2) 应用内按 LB / RB：仍然是滑动（且现在以光标为锚点）==="
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 1.5
for k in 310 311; do
  logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
  $VG key $k 400 2000 >/dev/null 2>&1
  sleep 1.0
  echo "   key=$k $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -m1 'SWIPE')"
done

echo "=== 3) 前台包名查询（助手 t 命令）==="
echo "   top(助手视角)=$(logcat -d -s DexPad | grep -c 'TOP ') 条 TOP 记录"
grep -a 'TOP ' /data/adb/gpm/helper.log 2>/dev/null | tail -2
