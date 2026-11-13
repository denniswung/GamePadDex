#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  ls -t /data/data/$PKG/files/snap_*.png | head -1
}
echo "== app on DeX, mouse mode on =="
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 2
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
# cursor to the middle of the window
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1280 --ef my 500 >/dev/null 2>&1
sleep 1
rm -f /data/data/$PKG/files/snap_*.png
A=$(snap); cp "$A" /data/local/tmp/a.png

echo "== RIGHT stick LEFT (linux ABS_RX=3, minus) =="
logcat -c
(/data/local/tmp/vgpad stick 3 -30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmGesture:I GpmPointer:I 2>/dev/null | grep -E "scroll on display" | tail -3
B=$(snap); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "A=$(stat -c%s /data/local/tmp/a.png)  B=$(stat -c%s /data/local/tmp/b.png)"

echo "== RIGHT stick RIGHT (ABS_RX=3, plus) =="
(/data/local/tmp/vgpad stick 3 30000 1500 2400 >/dev/null 2>&1 &)
sleep 5
C=$(snap); cp "$C" /data/local/tmp/c.png; chmod 666 /data/local/tmp/c.png
echo "C=$(stat -c%s /data/local/tmp/c.png)"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
