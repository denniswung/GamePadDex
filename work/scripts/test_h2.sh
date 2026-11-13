#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
chmod 755 /data/local/tmp/vgpad /data/adb/gpm/gpminput
chmod 644 /data/adb/gpm/inject.dex
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 0.8
rm -f $SOCK /data/data/$PKG/files/snap_*.png
mkdir -p /data/data/$PKG/files
/data/adb/gpm/gpminput --socket $SOCK >/data/local/tmp/gpm.log 2>&1 &
DPID=$!
sleep 4
echo "daemon=$DPID alive=$(kill -0 $DPID 2>/dev/null && echo yes || echo no)"
tail -2 /data/local/tmp/gpm.log

settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== connectivity =="
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "helper ready|connected|mouse mode" | tail -3
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1280 --ef my 500 >/dev/null 2>&1
sleep 1
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"

echo "== right stick LEFT 1.2s =="
(/data/local/tmp/vgpad stick 3 -30000 1200 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmAxis:I GpmGesture:I GpmPointer:I 2>/dev/null | grep -E "axis=12|axis=13|scroll on display|injector" | tail -8
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
kill $DPID 2>/dev/null
