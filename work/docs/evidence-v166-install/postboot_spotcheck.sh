#!/system/bin/sh
# v1.66 post-reboot spot check: helper alive + real cursor readable + mouse move works
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
logcat -c 2>/dev/null
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
echo "=== focus ==="
dumpsys window | grep -m1 mCurrentFocus
echo "=== helper alive? ==="
echo "helper_pid=$(pidof gpminput) app_pid=$(pidof $PKG)"
echo "=== CURSOR req#1 ==="
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "c" >/dev/null 2>&1
sleep 1.2
logcat -d 2>/dev/null | grep -E 'CURSOR' | tail -2
echo "=== stick move (0.9,0.2,700ms) ==="
$VG stick 0.9 0.2 700 0
sleep 1.2
echo "=== CURSOR req#2 ==="
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "c" >/dev/null 2>&1
sleep 1.2
logcat -d 2>/dev/null | grep -E 'CURSOR' | tail -2
echo "=== engine pointer lines ==="
logcat -d 2>/dev/null | grep -E 'POINTER|pointer|moveGain|geometry' | tail -6
echo "=== helper.log tail ==="
tail -6 /data/adb/gpm/helper.log 2>/dev/null
