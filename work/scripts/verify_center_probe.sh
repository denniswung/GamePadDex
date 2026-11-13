#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

# 先把指针弄到右下角
$VG stick 0 20000 300 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 4 20000 300 0 >/dev/null 2>&1
sleep 0.4
echo "角落: $(hover)"

# 助手居中
logcat -c
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "O 2560 1600" >/dev/null 2>&1
sleep 0.9

# 左移一小步，把指针"唤醒"出 hover
$VG stick 0 -2500 200 0 >/dev/null 2>&1
sleep 0.5
H1=$(hover)
$VG stick 0 -2500 200 0 >/dev/null 2>&1
sleep 0.5
H2=$(hover)
echo "左移1: $H1"
echo "左移2: $H2"
grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1
echo "wm size: $(wm size | tr '\n' ' ')"
