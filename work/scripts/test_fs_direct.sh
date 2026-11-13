#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== am start windowingMode 1 on display 8 =="
am start --display 8 --windowingMode 1 -n com.example.piliplus/.MainActivity 2>&1 | head -3
sleep 4
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
cp "$F" /data/local/tmp/fs2.png
chmod 666 /data/local/tmp/fs2.png
echo "shot=$(stat -c%s /data/local/tmp/fs2.png)"
dumpsys activity activities 2>/dev/null | grep -m2 -E "topResumedActivity|windowingMode="
