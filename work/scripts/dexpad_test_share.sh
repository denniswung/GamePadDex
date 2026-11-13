#!/system/bin/sh
# verify the Xbox Share button (KEY_RECORD=167 -> MEDIA_RECORD=130 -> "share")
B=com.dennis.dexpad
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button share --es mapped recents >/dev/null 2>&1
sleep 1
logcat -c
/data/local/tmp/vgpad key 167 300 6000 >/dev/null 2>&1
sleep 1
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -E 'button share|recents' | tail -4
echo "== dex top =="
dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity' | head -2
