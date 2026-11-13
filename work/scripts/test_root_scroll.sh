#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
chmod 644 $DEX
pkill -f "ScrollInject" 2>/dev/null
sleep 0.6
setsid app_process -Djava.class.path=$DEX /system/bin ScrollInject gpm_scroll >/data/local/tmp/inject.log 2>&1 </dev/null &
sleep 3
tail -3 /data/local/tmp/inject.log
echo "== service =="
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3

echo "== open Bilibili on DeX =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
rm -f /data/data/$PKG/files/snap_*.png
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/a.png
echo "A=$(stat -c%s /data/local/tmp/a.png)"

echo "== right stick down (app -> root injector) =="
logcat -c
(/data/local/tmp/vgpad stick 4 30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmInjector:I GpmPointer:I 2>/dev/null | tail -5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B=$(stat -c%s /data/local/tmp/b.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
