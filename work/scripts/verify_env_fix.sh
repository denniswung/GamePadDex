#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
chmod 755 /data/adb/gpm/gpminput
# restart everything, once
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -9 -f ScrollInject
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
echo "== injector =="
ps -A -o PID,NAME | grep ScrollInject | grep -v grep
echo "== log =="
tail -5 /data/local/tmp/gpm-module.log
echo "== live test: scroll on DeX =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 4
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/bA.png; chmod 666 /data/local/tmp/bA.png
echo "before=$(stat -c%s /data/local/tmp/bA.png)"
echo "m 8 1280 800 1" | sh -c 'export ANDROID_ROOT=/system; export ANDROID_DATA=/data; export LD_LIBRARY_PATH=/apex/com.android.art/lib64:/system/lib64:/system_ext/lib64; exec app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin ScrollInject --stdio' 2>&1 | tail -2
