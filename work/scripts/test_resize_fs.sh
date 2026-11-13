#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
for p in $(ps -A -o PID,STAT,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -f 'gpm_dex/service.sh'; pkill -f ScrollInject
sleep 2
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 /data/adb/gpm/gpminput $MOD/gpminput
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/local/tmp/helper.log 2>&1 </dev/null &
sleep 3
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
# make it windowed first so the action has work to do
am task resize 243 900 300 2300 1400 >/dev/null 2>&1
sleep 2
echo "bounds before:"
dumpsys activity activities 2>/dev/null | grep -m3 'bounds=\[' | tail -2
logcat -c
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/fsA.png; chmod 666 /data/local/tmp/fsA.png
echo "before_shot=$(stat -c%s /data/local/tmp/fsA.png)"
echo "== dex_fullscreen =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 5
logcat -d -s GpmService:I 2>/dev/null | grep -E "dex_fullscreen|CAPTION" | tail -3
grep -E "FULLSCREEN|CAPTION" /data/local/tmp/helper.log | tail -4
echo "bounds after:"
dumpsys activity activities 2>/dev/null | grep -m3 'bounds=\[' | tail -2
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/fsB.png; chmod 666 /data/local/tmp/fsB.png
echo "after_shot=$(stat -c%s /data/local/tmp/fsB.png)"
