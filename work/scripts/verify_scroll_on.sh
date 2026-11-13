#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
# make sure we are in mouse mode and the DeX display is awake
input keyevent KEYCODE_WAKEUP
sleep 1
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
A=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$A" /data/local/tmp/zA.png; chmod 666 /data/local/tmp/zA.png
echo "before=$(stat -c%s /data/local/tmp/zA.png)"
logcat -c
/data/local/tmp/vgpad stick 4 30000 1800 2600 >/dev/null 2>&1 &
sleep 7
echo "axis/scroll log:"
logcat -d 2>/dev/null | grep -E 'axis=13|axis=14|scroll on display|GpmAxis' | tail -4
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
B=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$B" /data/local/tmp/zB.png; chmod 666 /data/local/tmp/zB.png
echo "after=$(stat -c%s /data/local/tmp/zB.png)"
