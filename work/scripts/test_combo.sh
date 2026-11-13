#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
grep -q 'name="pref_combo_0_keys"' $SU || sed -i 's|</map>|<string name="pref_combo_0_keys">x+a</string>\n</map>|' $SU
sed -i 's|<string name="pref_combo_0_keys">[^<]*</string>|<string name="pref_combo_0_keys">x+a</string>|' $SU
sed -i 's|<string name="pref_combo_0_type">[^<]*</string>|<string name="pref_combo_0_type">home</string>|' $SU
grep -E 'pref_combo_0' $SU
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c

echo "== combo X+A (307 + 304) =="
/data/local/tmp/vgpad combo 307 304 700 2>/dev/null
sleep 3
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction" | tail -6

# restore
sed -i 's|<string name="pref_combo_0_type">[^<]*</string>|<string name="pref_combo_0_type">none</string>|' $SU
am force-stop $PKG
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
