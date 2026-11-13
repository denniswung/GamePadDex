#!/system/bin/sh
PKG=com.dennis.gamepadmouse
BIN=/data/local/tmp/gpminput
chmod 755 /data/local/tmp/vgpad $BIN
echo "== state before =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action snap >/dev/null 2>&1
sleep 1.5
logcat -c
echo "== press A (grab first, then key) =="
(/data/local/tmp/vgpad key 304 120 2600 >/dev/null 2>&1 &)
sleep 4.5
echo "== log =="
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | tail -12
echo "== focus =="
dumpsys window 2>/dev/null | grep -E "mCurrentFocus" | head -4
echo "== snap after =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action snap >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -2
