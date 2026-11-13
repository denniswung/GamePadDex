#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -c
echo "== horizontal only (ABS_RX = 3) =="
/data/local/tmp/vgpad stick 3 -30000 1400 2600 >/dev/null 2>&1 &
sleep 6
logcat -d -s GpmGesture:I 2>/dev/null | grep "scroll on display" | awk '{print $NF, $(NF-1)}' | sort | uniq -c | head -5
echo "== vertical only (ABS_RY = 4) =="
logcat -c
/data/local/tmp/vgpad stick 4 30000 1400 2600 >/dev/null 2>&1 &
sleep 6
logcat -d -s GpmGesture:I 2>/dev/null | grep "scroll on display" | awk '{print $NF, $(NF-1)}' | sort | uniq -c | head -5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
