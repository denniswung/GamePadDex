#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad

layers() { dumpsys SurfaceFlinger --list 2>/dev/null | grep -iE 'pointer|cursor' | sort | tr '\n' ' '; }

$VG key 317 100 2000 >/dev/null 2>&1
sleep 0.8
echo "before : $(layers)"
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd h >/dev/null 2>&1
sleep 1.2
echo "after h: $(layers)"
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd j >/dev/null 2>&1
sleep 1.2
echo "after j: $(layers)"
echo "--- dumpsys input pointer ---"
dumpsys input 2>/dev/null | grep -iE 'pointer.*(visible|icon|down)' | head -5
