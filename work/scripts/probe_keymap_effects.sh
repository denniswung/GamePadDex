#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
shade(){ dumpsys window 2>/dev/null | grep -m1 -oE 'mNotificationShade=.*(visible|statusBar)' ; }
vol(){ dumpsys audio 2>/dev/null | grep -A2 'STREAM_MUSIC' | grep -m1 'streamVolume:' | sed 's/^ *//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1

echo "=== 1) 通知栏：input keyevent 83（shell 域对照）==="
input keyevent 83
sleep 1
echo "  shade: $(dumpsys window 2>/dev/null | grep -c 'NotificationShade')"
input keyevent 4 >/dev/null 2>&1; sleep 0.5

echo "=== 2) 通知栏：uinput K 444 (KEY_NOTIFICATION_CENTER) ==="
hcmd "K 444 1"; sleep 0.1; hcmd "K 444 0"
sleep 1.2
echo "  shade: $(dumpsys window 2>/dev/null | grep -c 'NotificationShade')"
input keyevent 4 >/dev/null 2>&1; sleep 0.5

echo "=== 3) 返回键：K 158 ==="
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
B=$(top)
hcmd "K 158 1"; sleep 0.08; hcmd "K 158 0"
sleep 1.2
echo "  before=$B after=$(top)"

echo "=== 4) 音量加：K 115 ==="
echo "  before: $(vol)"
hcmd "K 115 1"; sleep 0.08; hcmd "K 115 0"
sleep 1
echo "  after : $(vol)"

echo "=== 5) 静音：K 113 ==="
hcmd "K 113 1"; sleep 0.08; hcmd "K 113 0"
sleep 1
echo "  after mute: $(vol)"
