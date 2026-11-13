#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
chmod 755 /data/local/tmp/vgpad /data/adb/gpm/gpminput
killall gpminput 2>/dev/null; pkill -f ScrollInject 2>/dev/null
sleep 0.8
rm -f $SOCK /data/data/$PKG/files/snap_*.png
mkdir -p /data/data/$PKG/files
/data/adb/gpm/gpminput --socket $SOCK >/data/local/tmp/gpm.log 2>&1 &
DPID=$!
sleep 4
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1280 --ef my 700 >/dev/null 2>&1
sleep 1
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"

echo "== horizontal LEFT (vgpad ABS_RX=-30000) =="
(/data/local/tmp/vgpad stick 3 -30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmService:I GpmPointer:I GpmGesture:I 2>/dev/null | grep -E "hscroll|HSCROLL|scroll on display" | tail -6
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$B" /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"

echo "== horizontal RIGHT (vgpad ABS_RX=+30000) =="
(/data/local/tmp/vgpad stick 3 30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
C=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$C" /data/local/tmp/c.png
echo "C=$(stat -c%s /data/local/tmp/c.png)"
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png /data/local/tmp/c.png
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
kill $DPID 2>/dev/null
