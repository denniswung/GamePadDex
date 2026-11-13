#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -c
echo "== vgpad right stick down (linux ABS_RY=4) =="
/data/local/tmp/vgpad stick 4 30000 1500 2600 >/dev/null 2>&1 &
sleep 6
logcat -d -s GpmService:I GpmPointer:I GpmGesture:I GpmAxis:I 2>/dev/null | grep -E "axis=13|scroll|swipe|display 8" | tail -8
