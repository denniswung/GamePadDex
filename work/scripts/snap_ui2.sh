#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$A11Y"
sleep 4
echo "== service alive? =="
ps -A | grep "$PKG" | grep -v grep
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 3
rm -f /data/data/$PKG/files/snap_*.png
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
LATEST=$(ls -t /data/data/$PKG/files/snap_*.png 2>/dev/null | head -1)
echo "snapshot: $LATEST"
if [ -n "$LATEST" ]; then
  cp "$LATEST" /data/local/tmp/s.png
  chmod 666 /data/local/tmp/s.png
fi
