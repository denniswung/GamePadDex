#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -f 'gpm_dex/service.sh'
pkill -f ScrollInject
sleep 2
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 /data/adb/gpm/gpminput $MOD/gpminput
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
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
echo "== press Y =="
/data/local/tmp/vgpad key 308 120 3200 >/dev/null 2>&1
sleep 4
logcat -d 2>/dev/null | grep -E "GpmService|GpmRootInput" | grep -E "mapped key|fireAction|dex_fullscreen|CAPTION" | tail -6
echo "== injector log =="
tail -3 /data/local/tmp/gpm-module.log 2>/dev/null
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/mapped2.png; chmod 666 /data/local/tmp/mapped2.png
echo "shot=$(stat -c%s /data/local/tmp/mapped2.png)"
