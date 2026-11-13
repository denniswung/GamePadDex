#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -f 'gpm_dex/service.sh'; pkill -f ScrollInject
sleep 2
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 /data/adb/gpm/gpminput $MOD/gpminput
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/local/tmp/helper.log 2>&1 </dev/null &
sleep 3
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
logcat -c
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/b1.png; chmod 666 /data/local/tmp/b1.png
echo "before=$(stat -c%s /data/local/tmp/b1.png)"
echo "== action =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 4
logcat -d -s GpmService:I 2>/dev/null | grep -E "dex_fullscreen|helper: CAPTION" | tail -4
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/b2.png; chmod 666 /data/local/tmp/b2.png
echo "after=$(stat -c%s /data/local/tmp/b2.png)"
