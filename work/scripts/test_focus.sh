#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
chmod 755 /data/local/tmp/vgpad /data/adb/gpm/gpminput
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

echo "== A: Bilibili on DeX (display 9) =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 5
logcat -d -s GpmService:I GpmPointer:I 2>/dev/null | grep -E "pick: focus|attach display|ATTACH" | tail -3

echo "== B: launch something on the phone display (focus -> 0) =="
am start --display 0 -a android.settings.SETTINGS >/dev/null 2>&1
sleep 5
logcat -d -s GpmService:I GpmPointer:I 2>/dev/null | grep -E "pick: focus|attach display|ATTACH" | tail -3

echo "== C: back to DeX (focus -> 9) =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 5
logcat -d -s GpmService:I GpmPointer:I 2>/dev/null | grep -E "pick: focus|attach display|ATTACH" | tail -3
kill $DPID 2>/dev/null
