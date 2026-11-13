#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">key_combo</string>|' $SU
grep -q 'name="pref_btn_y_value"' $SU \
  && sed -i 's|<string name="pref_btn_y_value">[^<]*</string>|<string name="pref_btn_y_value">ctrl+alt+f</string>|' $SU \
  || sed -i 's|</map>|<string name="pref_btn_y_value">ctrl+alt+f</string>\n</map>|' $SU
am force-stop $PKG
sleep 0.5
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
echo "== displays =="
dumpsys display 2>/dev/null | grep -E "mDisplayId=|DisplayDeviceInfo\{" | head -6
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
(/data/local/tmp/vgpad key 308 120 2600 >/dev/null 2>&1 &)
sleep 5
echo "== combo targeting =="
logcat -d -s GpmService:I 2>/dev/null | grep -E "key_combo|mapped key|display" | tail -5
tail -2 /data/local/tmp/gpm-module.log
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
