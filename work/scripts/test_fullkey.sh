#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
# preset: map button Y -> toggle_mouse, and combo X+A -> home
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
xml_set() { sed -i "s|<string name=\"$1\">[^<]*</string>|<string name=\"$1\">$2</string>|" $SU; }
xml_add() { grep -q "name=\"$1\"" $SU || sed -i "s|</map>|<string name=\"$1\">$2</string>\n</map>|" $SU; }

settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c

echo "== set pref_btn_y_type=toggle_mouse + combo0 (x+a)->home =="
am force-stop $PKG
sleep 1
xml_add pref_btn_y_type toggle_mouse
xml_add pref_combo_0_keys x+a
xml_add pref_combo_0_type home
grep -E 'pref_btn_y_type|pref_combo_0' $SU
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3

echo "== press Y (linux BTN_WEST=308) -> expect toggle_mouse =="
logcat -c
(/data/local/tmp/vgpad key 308 120 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmService:I 2>/dev/null | grep -E "fireAction|mouse mode" | tail -4

echo "== press X+A (307 + 304) -> expect combo home =="
logcat -c
(
  /data/local/tmp/vgpad key 307 60 2200 >/dev/null 2>&1 &
  sleep 0.2
  /data/local/tmp/vgpad key 304 120 2400 >/dev/null 2>&1
) &
sleep 6
logcat -d -s GpmService:I 2>/dev/null | grep -E "fireAction|mouse mode" | tail -4

echo "== cleanup prefs =="
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
sed -i 's|<string name="pref_combo_0_type">[^<]*</string>|<string name="pref_combo_0_type">none</string>|' $SU
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
