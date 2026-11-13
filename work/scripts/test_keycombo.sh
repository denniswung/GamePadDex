#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
MOD=/data/adb/modules/gpm_dex
chmod 755 /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $MOD/gpminput; chmod 755 $MOD/gpminput
cp -f /data/local/tmp/inject.dex $MOD/inject.dex; chmod 644 $MOD/inject.dex
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput; chmod 755 /data/adb/gpm/gpminput
cp -f /data/local/tmp/inject.dex /data/adb/gpm/inject.dex; chmod 644 /data/adb/gpm/inject.dex
# map Y -> key_combo ctrl+alt+f
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">key_combo</string>|' $SU
grep -q 'name="pref_btn_y_value"' $SU \
  && sed -i 's|<string name="pref_btn_y_value">[^<]*</string>|<string name="pref_btn_y_value">ctrl+alt+f</string>|' $SU \
  || sed -i 's|</map>|<string name="pref_btn_y_value">ctrl+alt+f</string>\n</map>|' $SU
grep -E 'pref_btn_y_' $SU
pkill -f ScrollInject 2>/dev/null; killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
am force-stop $PKG
sleep 0.5
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== press Y (ctrl+alt+f) =="
(/data/local/tmp/vgpad key 308 120 2600 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction|COMBO|combo" | tail -5
echo "== injector log =="
tail -3 /data/local/tmp/gpm-module.log 2>/dev/null
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
