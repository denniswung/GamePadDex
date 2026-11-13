#!/system/bin/sh
PKG=com.dennis.gamepadmouse
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
logcat -c
echo "== trigger dex_fullscreen via debug broadcast =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I 2>/dev/null | grep -E "titlebar cand|dex fullscreen|dex_fullscreen" | tail -12
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/fs6.png; chmod 666 /data/local/tmp/fs6.png
echo "shot=$(stat -c%s /data/local/tmp/fs6.png)"
