#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
chmod 755 /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
chmod 755 /data/adb/gpm/gpminput
pkill -f ScrollInject 2>/dev/null
killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
echo "== helper + injector =="
ps -A | grep -c gpminput
ps -A | grep -c ScrollInject
cat /data/local/tmp/gpm-module.log | tail -2

settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== chain =="
logcat -d -s GpmService:I GpmPointer:I 2>/dev/null | grep -E "display 9|mouse mode|root helper" | tail -3

echo "== kill the injector child, watch the watchdog =="
INJ=$(ps -A | grep ScrollInject | awk '{print $2}' | head -1)
echo "injector pid=$INJ"
kill -9 $INJ 2>/dev/null
sleep 4
echo "after kill: injector count=$(ps -A | grep -c ScrollInject)"
tail -4 /data/local/tmp/gpm-module.log

echo "== scroll still works after respawn? =="
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
