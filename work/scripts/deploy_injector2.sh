#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/inject.sock
DEX=/data/adb/gpm/inject.dex
chmod 644 $DEX
pkill -f "ScrollInject" 2>/dev/null
sleep 0.6
rm -f $SOCK
mkdir -p /data/data/$PKG/files
setsid app_process -Djava.class.path=$DEX /system/bin ScrollInject $SOCK >/data/local/tmp/inject.log 2>&1 </dev/null &
sleep 3
echo "== injector =="
ls -l $SOCK 2>&1
tail -3 /data/local/tmp/inject.log
echo "== restart accessibility =="
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
echo ok
