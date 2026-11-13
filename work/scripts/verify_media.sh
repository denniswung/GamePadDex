#!/system/bin/sh
PKG=com.dennis.gamepadmouse
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
: > /data/local/tmp/gpm-module.log
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== press Y (builtin: media play/pause) =="
/data/local/tmp/vgpad key 308 120 3200 >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I 2>/dev/null | grep -E "media key|pick:" | tail -4
echo "== injector (KeyEvent path) =="
tail -3 /data/local/tmp/gpm-module.log
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
