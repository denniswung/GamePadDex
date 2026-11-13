#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
pkill -f gpminput 2>/dev/null
sleep 0.6
rm -f $SOCK
nohup /data/local/tmp/gpminput --socket $SOCK >/dev/null 2>&1 &
sleep 1.5
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 3
sh /data/local/tmp/t15.sh
