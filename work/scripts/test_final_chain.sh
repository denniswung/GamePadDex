#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== chain =="
logcat -d -s GpmService:I GpmPointer:I GpmRootInput:I 2>/dev/null | grep -E "ATTACH|display 9|mouse mode|helper ready|connected" | tail -4
rm -f /data/data/$PKG/files/snap_*.png
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"
echo "== vertical scroll =="
(/data/local/tmp/vgpad stick 4 30000 1300 2400 >/dev/null 2>&1 &)
sleep 5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$B" /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"
echo "== horizontal swipe =="
(/data/local/tmp/vgpad stick 3 -30000 1300 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmGesture:I 2>/dev/null | grep -c "scroll on display"
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
C=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$C" /data/local/tmp/c.png
echo "C=$(stat -c%s /data/local/tmp/c.png)"
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png /data/local/tmp/c.png
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
