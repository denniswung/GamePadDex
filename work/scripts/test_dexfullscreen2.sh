#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
cp -f /data/local/tmp/gpminput $MOD/gpminput; chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput; chmod 755 /data/adb/gpm/gpminput
cp -f /data/local/tmp/inject.dex /data/adb/gpm/inject.dex; chmod 644 /data/adb/gpm/inject.dex
pkill -f 'gpm_dex/service.sh' 2>/dev/null
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 1
rm -f /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 5
# make sure the app is windowed (not fullscreen) so the click has something to do
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 3
logcat -c
echo "== run dex_fullscreen =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I 2>/dev/null | grep -E "dex_fullscreen|CAPTION" | tail -4
tail -3 /data/local/tmp/gpm-module.log 2>/dev/null
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/df.png; chmod 666 /data/local/tmp/df.png
echo "shot=$(stat -c%s /data/local/tmp/df.png)"
