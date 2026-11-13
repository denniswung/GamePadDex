#!/system/bin/sh
PKG=com.dennis.gamepadmouse
rm -f /data/data/$PKG/files/snap_*.png
am force-stop $PKG
sleep 1
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 3
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
LATEST=$(ls -t /data/data/$PKG/files/snap_*.png 2>/dev/null | head -1)
echo "snapshot: $LATEST"
if [ -n "$LATEST" ]; then
  cp "$LATEST" /data/local/tmp/s.png
  chmod 666 /data/local/tmp/s.png
fi
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -1
