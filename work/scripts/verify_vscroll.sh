#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
input keyevent KEYCODE_WAKEUP
sleep 1
svc power stayon true 2>/dev/null
settings put system screen_off_timeout 600000
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/scA.png; chmod 666 /data/local/tmp/scA.png
echo "before=$(stat -c%s /data/local/tmp/scA.png)"
logcat -c
echo "== right stick down =="
/data/local/tmp/vgpad stick 4 30000 1600 2600 >/dev/null 2>&1 &
sleep 7
logcat -d -s GpmService:I GpmPointer:I GpmGesture:I 2>/dev/null | grep -E "scroll on display|axis=13|display 8" | tail -5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/scB.png; chmod 666 /data/local/tmp/scB.png
echo "after=$(stat -c%s /data/local/tmp/scB.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
