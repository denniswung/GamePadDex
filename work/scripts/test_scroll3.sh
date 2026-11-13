#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad
snap() { rm -f /data/data/$PKG/files/snap_*.png; am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1; sleep 2.5; ls -t /data/data/$PKG/files/snap_*.png 2>/dev/null | head -1; }

settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
sleep 1

echo "== open Settings on DeX display =="
am start --display 8 -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3

echo "== switch to GESTURE backend =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "mouse mode" | tail -1

echo "== cursor to (1280,800) =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1280 --ef my 800 >/dev/null 2>&1
sleep 1
A=$(snap); echo "snapA=$A"
if [ -n "$A" ]; then cp "$A" /data/local/tmp/a.png; chmod 666 /data/local/tmp/a.png; fi

echo "== right stick down (ABS_RY) =="
logcat -c
(/data/local/tmp/vgpad stick 4 30000 1800 2400 >/dev/null 2>&1 &)
sleep 6
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "rstick|scroll" | tail -6
B=$(snap); echo "snapB=$B"
if [ -n "$B" ]; then cp "$B" /data/local/tmp/b.png; chmod 666 /data/local/tmp/b.png; fi
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
