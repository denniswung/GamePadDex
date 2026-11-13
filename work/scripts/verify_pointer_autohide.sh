#!/system/bin/sh
# 验证空闲自动隐藏指针：日志里应出现 pointer hidden / shown
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

logcat -c
echo "等 10 秒（默认 8s 空闲触发）..."
sleep 10
echo "--- 引擎 ---"
logcat -d -s DexPad | grep -E 'pointer (hidden|shown)' | sed 's/^.*DexPad  : /  /'
echo "--- 助手 ---"
grep -a 'POINTER' /data/adb/gpm/helper.log | tail -2

echo "推一下摇杆，应立刻恢复"
logcat -c
$VG stick 0 20000 300 2000 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad | grep -E 'pointer (hidden|shown)' | sed 's/^.*DexPad  : /  /'

echo "关鼠标模式应隐藏，开回来应恢复"
logcat -c
input keyevent KEYCODE_NONE >/dev/null 2>&1
am broadcast -a $PKG.MODE -n $PKG/.DebugReceiver --ez enabled false >/dev/null 2>&1
sleep 1.2
am broadcast -a $PKG.MODE -n $PKG/.DebugReceiver --ez enabled true >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | grep -E 'pointer (hidden|shown)|mouse mode' | sed 's/^.*DexPad  : /  /'
