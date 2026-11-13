#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad
echo "== state =="
logcat -d -s GpmRootInput:I GpmService:I GpmPointer:I 2>/dev/null | grep -E "connected to helper|helper ready|gamepad:|grabbed|mouse mode|display [0-9]" | tail -5
echo "== mouse mode on, open Bilibili on DeX =="
input keyevent KEYCODE_WAKEUP
sleep 1
svc power stayon true 2>/dev/null
settings put system screen_off_timeout 600000
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 3
logcat -c
echo "== scroll with the right stick down =="
(/data/local/tmp/vgpad stick 4 30000 1500 2600 >/dev/null 2>&1 &)
sleep 6
logcat -d -s GpmService:I GpmPointer:I GpmGesture:I 2>/dev/null | grep -E "scroll|axis=13|HSCROLL|display" | tail -6
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/scr.png; chmod 666 /data/local/tmp/scr.png
echo "shot=$(stat -c%s /data/local/tmp/scr.png)"
