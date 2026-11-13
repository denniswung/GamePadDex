#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
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
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l) injectors=$(ps -A -o PID,NAME | grep ScrollInject | grep -v grep | wc -l)"
echo "== CANNOT LINK still there? =="
grep -c "CANNOT LINK" /data/local/tmp/gpm-module.log 2>/dev/null
echo "== fullscreen action test =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 4
am task resize 243 900 300 2300 1400 >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/fA.png; chmod 666 /data/local/tmp/fA.png
echo "before=$(stat -c%s /data/local/tmp/fA.png)"
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 5
grep -E "CAPTION|FULLSCREEN" /data/local/tmp/gpm-module.log | tail -4
dumpsys activity activities 2>/dev/null | grep -m2 'bounds=\[' | tail -1
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/fB.png; chmod 666 /data/local/tmp/fB.png
echo "after=$(stat -c%s /data/local/tmp/fB.png)"
