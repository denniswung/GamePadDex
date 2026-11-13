#!/system/bin/sh
PKG=com.dennis.gamepadmouse
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
try_back() {
  echo "  sending BACK"
  (/data/local/tmp/vgpad key 158 120 2200 >/dev/null 2>&1 &)
  sleep 4
}
top_dex() {
  dumpsys activity activities 2>/dev/null | sed -n '/Display #8/,/Display #/p' | grep -m2 -E 'topResumedActivity|\* Task' | head -2
}

echo "== open Settings on the DeX display =="
am start --display 8 -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
top_dex

echo "== mouse mode ON (gamepad grabbed) =="
am broadcast -a $PKG.TOGGLE -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -2
echo "-- BACK while grabbed (should be ignored by the system) --"
try_back
top_dex

echo "== mouse mode OFF (gamepad released) =="
am broadcast -a $PKG.TOGGLE -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -2
echo "-- BACK while released (system should react) --"
top_dex
try_back
top_dex
