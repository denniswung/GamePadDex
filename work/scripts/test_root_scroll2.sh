#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
BIN=/data/adb/gpm/gpminput
chmod 644 $DEX
chmod 755 $BIN
pkill -f ScrollInject 2>/dev/null
killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock
mkdir -p /data/data/$PKG/files
setsid $BIN --socket /data/data/$PKG/files/gpm.sock >/data/local/tmp/gpm.log 2>&1 </dev/null &
sleep 4
echo "== helper log =="
tail -4 /data/local/tmp/gpm.log
echo "== injector process =="
ps -A | grep -c ScrollInject

echo "== reload accessibility =="
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3

echo "== Bilibili on DeX, mouse mode on =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
rm -f /data/data/$PKG/files/snap_*.png
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"

echo "== right stick down =="
logcat -c
(/data/local/tmp/vgpad stick 4 30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmPointer:I 2>/dev/null | tail -3
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
