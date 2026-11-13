#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
chmod 755 /data/local/tmp/vgpad
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
grep -E 'pref_btn_y_type|pref_btn_y_value' $SU || echo "(y mapping absent)"
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">dex_fullscreen</string>|' $SU
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
logcat -c
echo "== press Y (mapped to dex_fullscreen) =="
/data/local/tmp/vgpad key 308 120 3200 >/dev/null 2>&1
sleep 4
logcat -d 2>/dev/null | grep -E "GpmService|GpmRootInput" | grep -E "mapped key|fireAction|dex_fullscreen|CAPTION|grabbed|gamepad:" | tail -8
echo "== screenshot =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/mapped.png; chmod 666 /data/local/tmp/mapped.png
echo "shot=$(stat -c%s /data/local/tmp/mapped.png)"
