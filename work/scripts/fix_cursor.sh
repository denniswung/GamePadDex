#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "helpers=$(ps -A -o PID,STAT,NAME | grep gpminput | grep -v grep | wc -l)"
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
logcat -c
echo "== service state =="
logcat -d -s GpmService:I GpmRootInput:I GpmPointer:I 2>/dev/null | grep -E "connected|helper ready|display [0-9]|always-grab|mouse mode" | tail -6
echo "== toggle mouse mode ON =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I GpmPointer:I GpmRootInput:I 2>/dev/null | grep -E "mouse mode|display [0-9]|cursor|helper ready" | tail -6
echo "== screenshot =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/cur.png; chmod 666 /data/local/tmp/cur.png
echo "shot=$(stat -c%s /data/local/tmp/cur.png)"
