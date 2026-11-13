#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
$VG stick 0 20000 250 2000 >/dev/null 2>&1
sleep 0.4
echo "初始: $(hover)"

logcat -c
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "O 2560 1600" >/dev/null 2>&1
sleep 0.8
echo "居中后(未抖动): $(hover)"

# 大幅右移，看指针从哪里继续
$VG stick 0 20000 500 0 >/dev/null 2>&1
sleep 0.6
echo "右移后: $(hover)"
grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1
