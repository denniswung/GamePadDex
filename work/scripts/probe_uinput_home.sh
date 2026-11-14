#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2
echo "before: $(top)"

echo "--- K 102 (KEY_HOME) 按下 80ms ---"
hcmd "K 102 1"; sleep 0.08; hcmd "K 102 0"
sleep 1.5
echo "after K102: $(top)"

echo "--- K 172 (KEY_HOMEPAGE) ---"
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
hcmd "K 172 1"; sleep 0.08; hcmd "K 172 0"
sleep 1.5
echo "after K172: $(top)"

echo "--- input keyevent 3（从 shell 域，作对照）---"
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
input keyevent 3
sleep 1.5
echo "after input: $(top)"
