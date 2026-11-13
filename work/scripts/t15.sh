#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 755 /data/local/tmp/vgpad /data/local/tmp/gpminput
topline() {
  dumpsys activity activities 2>/dev/null | sed -n '/Display #8/,/Display #0/p' | grep -m1 topResumedActivity
}
open_settings() {
  am start --display 8 -a android.settings.SETTINGS >/dev/null 2>&1
  sleep 3
}
send_back() {
  (/data/local/tmp/vgpad key 158 120 2300 >/dev/null 2>&1 &)
  sleep 4
}

logcat -c
echo "### A) mouse mode OFF - system should react to BACK"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
sleep 1.5
open_settings
echo "before: $(topline)"
send_back
echo "after : $(topline)"

echo
echo "### B) mouse mode ON (grabbed) - system must NOT see BACK"
open_settings
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -1
echo "before: $(topline)"
send_back
echo "after : $(topline)"
