#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/cA.png; chmod 666 /data/local/tmp/cA.png
echo "before=$(stat -c%s /data/local/tmp/cA.png)"
logcat -c
/data/local/tmp/vgpad stick 4 30000 2000 2600 >/dev/null 2>&1 &
sleep 8
echo "== drag activity =="
logcat -d -s GpmGesture:I 2>/dev/null | grep -E "startScroll|continueScroll|scroll" | tail -4
logcat -d -s GpmGesture:I 2>/dev/null | grep -c "scroll"
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/cB.png; chmod 666 /data/local/tmp/cB.png
echo "after=$(stat -c%s /data/local/tmp/cB.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
