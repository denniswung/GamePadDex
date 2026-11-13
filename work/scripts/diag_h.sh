#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== processes =="
ps -A | grep -E "gpminput|ScrollInject" | head -5
echo "== helper log =="
tail -3 /data/local/tmp/gpm.log 2>/dev/null
echo "== app connectivity =="
logcat -d -s GpmRootInput:I 2>/dev/null | tail -3
echo "== restart helper if needed =="
if ! ps -A | grep -q "[g]pminput"; then
  killall gpminput 2>/dev/null
  sleep 0.5
  rm -f /data/data/$PKG/files/gpm.sock
  mkdir -p /data/data/$PKG/files
  setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/local/tmp/gpm.log 2>&1 </dev/null &
  sleep 4
fi
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
logcat -c
echo "== mode on =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "mouse mode|helper ready|connected" | tail -3
echo "== right stick LEFT =="
(/data/local/tmp/vgpad stick 3 -30000 1200 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmAxis:I GpmGesture:I GpmPointer:I 2>/dev/null | grep -E "axis=12|axis=13|axis=11|axis=14|scroll on display" | tail -8
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
