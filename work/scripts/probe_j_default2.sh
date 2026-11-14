#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5

echo "1) 放到已知位置 2000,500"
hcmd "P 2000 500 2560 1600"
sleep 1
echo "   hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

echo "2) 销毁鼠标设备 h"
hcmd "h"
sleep 1.5
logcat -c

echo "3) 重建 j，然后一小步 M 10 0"
hcmd "j"
sleep 1.0
hcmd "M 10 0"
sleep 1.0
echo "   重建后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"

echo "4) 再一步 M 100 0 观察增量"
hcmd "M 100 0"
sleep 0.8
echo "   再移动后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
echo "helper: $(grep -aE 'MOUSE_REOPEN|POINTER' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
