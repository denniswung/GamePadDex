#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
echo "== pref default =="
grep -E 'pref_always_grab' $SU || echo "(not set yet -> default true)"
echo "== open the Root/DeX settings page =="
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 3
logcat -c
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/ag.png; chmod 666 /data/local/tmp/ag.png
echo "shot=$(stat -c%s /data/local/tmp/ag.png)"
echo "== flip the switch through prefs + applyAlwaysGrab path =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action "" >/dev/null 2>&1
logcat -d -s GpmService:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready" | tail -3
