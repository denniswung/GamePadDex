#!/system/bin/sh
PKG=com.dennis.gamepadmouse
# wake the phone and the DeX display
input keyevent KEYCODE_WAKEUP
sleep 1
input -d 0 keyevent KEYCODE_WAKEUP 2>/dev/null
sleep 1
settings put system screen_off_timeout 600000
dumpsys deviceidle disable 2>/dev/null
svc power stayon true 2>/dev/null
sleep 1
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
echo "== focused window =="
dumpsys window windows 2>/dev/null | grep -m1 mCurrentFocus
dumpsys window windows 2>/dev/null | grep -m2 'containing=\['
logcat -c
echo "== dex_fullscreen =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 4
logcat -d -s GpmService:I 2>/dev/null | grep -E "dex_fullscreen|helper: CAPTION" | tail -4
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/fs8.png; chmod 666 /data/local/tmp/fs8.png
echo "shot=$(stat -c%s /data/local/tmp/fs8.png)"
