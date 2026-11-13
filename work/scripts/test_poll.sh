#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
killall gpminput 2>/dev/null; pkill -f ScrollInject 2>/dev/null
sleep 0.8
rm -f $SOCK
mkdir -p /data/data/$PKG/files
/data/adb/gpm/gpminput --socket $SOCK >/data/local/tmp/gpm.log 2>&1 &
DPID=$!
sleep 4
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
echo "== poll cadence (expect ~300ms) =="
sleep 4
logcat -d -s GpmService:I 2>/dev/null | grep -E "poll#" | tail -4
echo "== window event -> immediate refresh =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 1.5
logcat -d -s GpmService:I 2>/dev/null | grep -E "poll#|ATTACH|pick: focus" | tail -4
echo "== switch to phone display =="
am start --display 0 -a android.settings.SETTINGS >/dev/null 2>&1
sleep 1.5
logcat -d -s GpmService:I 2>/dev/null | grep -E "poll#|ATTACH|pick: focus" | tail -4
echo "== back to DeX =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 1.5
logcat -d -s GpmService:I 2>/dev/null | grep -E "poll#|ATTACH|pick: focus" | tail -4
kill $DPID 2>/dev/null
