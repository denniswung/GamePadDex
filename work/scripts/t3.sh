#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== service running? =="
ps -A -o PID,ARGS | grep -c "com.dennis.gamepadmouse"
sleep 1
logcat -c
echo "== toggle =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 1.5
echo "== log =="
logcat -d -s GpmService:V GpmPointer:V GpmRootInput:V 2>/dev/null | tail -10
echo "== windows =="
dumpsys window windows 2>/dev/null | grep -A3 "u0 com.dennis.gamepadmouse}:" | grep "mAttrs=" | head -4
echo "== focus =="
dumpsys window 2>/dev/null | grep -E 'mCurrentFocus' | head -4
echo "== stick =="
logcat -c
/data/local/tmp/vgpad stick 0 30000 1200 2>/dev/null
sleep 0.5
logcat -d -s GpmService:V 2>/dev/null | tail -12
echo "== windows after =="
dumpsys window windows 2>/dev/null | grep -A3 "u0 com.dennis.gamepadmouse}:" | grep "mAttrs=" | head -4
