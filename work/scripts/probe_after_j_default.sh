#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
# 先把光标移到右上角附近（建立已知状态）
hcmd "P 2400 200 2560 1600"
sleep 0.8
echo "baseline hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"
# 销毁鼠标设备（光标消失）
hcmd "h"
sleep 1.2
echo "--- hidden ---"
# 重建
hcmd "j"
sleep 1.0
logcat -c
# 重建后先不动，试着点一下看默认位置
$PWD/true 2>/dev/null
: > /data/adb/gpm/helper.log
hcmd "M 10 0"
sleep 0.8
echo "重建后移动 +10 的 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
