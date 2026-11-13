#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
chmod 755 /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $MOD/gpminput; chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput; chmod 755 /data/adb/gpm/gpminput
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
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 5
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
echo "== cursor sync =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "cursor synced|display 9|mouse mode" | tail -4
echo "== real pointer from SurfaceFlinger =="
dumpsys SurfaceFlinger 2>/dev/null | grep -A6 'Sprite' | grep -E '^    [0-9-]' | head -2
echo "== scroll works with synced position? =="
rm -f /data/data/$PKG/files/snap_*.png
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$A" /data/local/tmp/a.png
(/data/local/tmp/vgpad stick 4 30000 1300 2400 >/dev/null 2>&1 &)
sleep 5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png|head -1); cp "$B" /data/local/tmp/b.png
echo "A=$(stat -c%s /data/local/tmp/a.png)  B=$(stat -c%s /data/local/tmp/b.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
