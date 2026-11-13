#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
MOD=/data/adb/modules/gpm_dex
chmod 755 /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $MOD/gpminput; chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput; chmod 755 /data/adb/gpm/gpminput
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">dex_fullscreen</string>|' $SU
pkill -f ScrollInject 2>/dev/null; killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
: > /data/local/tmp/gpm-module.log
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== press Y -> dex_fullscreen =="
/data/local/tmp/vgpad key 308 120 3200 >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I 2>/dev/null | grep -E "dex fullscreen|fireAction|mapped key|pick:" | tail -5
tail -3 /data/local/tmp/gpm-module.log
echo "== foreground window =="
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
F=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$F" /data/local/tmp/fs.png; chmod 666 /data/local/tmp/fs.png
echo "shot=$(stat -c%s /data/local/tmp/fs.png)"
sed -i 's|<string name="pref_btn_y_type">[^<]*</string>|<string name="pref_btn_y_type">default</string>|' $SU
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
