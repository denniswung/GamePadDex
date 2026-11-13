#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">dex_fullscreen</string>|' $SU
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 5
logcat -c
echo "== mouse mode OFF (always-grab on): press Y =="
/data/local/tmp/vgpad key 308 120 3000 >/dev/null 2>&1
sleep 3
logcat -d 2>/dev/null | grep -E "GpmService|GpmRootInput" | grep -E "mapped key|fireAction|dex_fullscreen|grabbed|gamepad:" | tail -6
echo "== mouse mode ON: press Y =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -c
/data/local/tmp/vgpad key 308 120 3000 >/dev/null 2>&1
sleep 3
logcat -d 2>/dev/null | grep -E "GpmService" | grep -E "mapped key|fireAction|dex_fullscreen" | tail -4
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
