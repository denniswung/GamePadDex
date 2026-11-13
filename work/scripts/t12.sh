#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== move to taskbar Play Store icon =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ef mx 1651 --ef my 1566 >/dev/null 2>&1
sleep 1
logcat -c
echo "== single click A =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ez click true >/dev/null 2>&1
sleep 2.5
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | tail -6
echo "== focused app =="
dumpsys window 2>/dev/null | grep -E "mFocusedApp" | head -4
echo "== snap =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -1
