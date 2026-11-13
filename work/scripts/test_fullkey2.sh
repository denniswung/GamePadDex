#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
# 1) edit prefs FIRST (app may be running with a cached copy)
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">toggle_mouse</string>|' $SU
grep -q 'name="pref_combo_0_keys"' $SU || sed -i 's|</map>|<string name="pref_combo_0_keys">x+a</string>\n</map>|' $SU
sed -i 's|<string name="pref_combo_0_type">[^<]*</string>|<string name="pref_combo_0_type">home</string>|' $SU
grep -E 'pref_btn_y_type|pref_combo_0' $SU
# 2) restart the app so it reloads prefs
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c

echo "== press Y (linux 308 -> keycode 100) =="
(/data/local/tmp/vgpad key 308 120 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction|mouse mode" | tail -4

echo "== combo X+A =="
logcat -c
( /data/local/tmp/vgpad key 307 400 2300 >/dev/null 2>&1 & sleep 0.35; /data/local/tmp/vgpad key 304 120 2500 >/dev/null 2>&1 ) &
sleep 7
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction" | tail -4

# 3) restore defaults
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
sed -i 's|<string name="pref_combo_0_type">[^<]*</string>|<string name="pref_combo_0_type">none</string>|' $SU
am force-stop $PKG
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
