#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
killall gpminput 2>/dev/null; sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock /data/data/$PKG/files/snap_*.png
mkdir -p /data/data/$PKG/files
(setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 </dev/null &)
sleep 2
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3

echo "== open Bilibili on DeX display 9 =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
dumpsys activity activities 2>/dev/null | sed -n '/Display #9/,/Display #0/p' | grep -m1 topResumedActivity

echo "== mouse mode on, cursor into the content area =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1700 --ef my 500 >/dev/null 2>&1
sleep 1
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/a.png

echo "== right stick DOWN =="
logcat -c
(/data/local/tmp/vgpad stick 4 30000 1800 2600 >/dev/null 2>&1 &)
sleep 6
logcat -d -s GpmGesture:I 2>/dev/null | grep "scroll on display" | tail -2
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
ls -l /data/local/tmp/a.png /data/local/tmp/b.png
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
