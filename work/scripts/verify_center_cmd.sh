#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

$VG stick 0 20000 250 2000 >/dev/null 2>&1
sleep 0.4
$VG stick 4 20000 250 0 >/dev/null 2>&1
sleep 0.4
echo "初始: $(hover)"

# 直接让助手执行居中命令 O <w> <h>
logcat -c
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "O 2560 1600" >/dev/null 2>&1
sleep 0.8
# 再抖一下指针，强制产生 hover
$VG stick 1 3000 120 0 >/dev/null 2>&1
sleep 0.4
echo "居中后: $(hover)"
grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1

# 再试一次，确认可重复
logcat -c
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "O 2560 1600" >/dev/null 2>&1
sleep 0.7
$VG stick 1 -3000 120 0 >/dev/null 2>&1
sleep 0.4
echo "第二次: $(hover)"
