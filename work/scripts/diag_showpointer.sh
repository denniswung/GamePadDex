#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake; sleep 1
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.ProbeActivity >/dev/null 2>&1
sleep 2
echo "top=$(top) mode=$(grep -oE 'name=\"mode_on\" value=\"[a-z]+\"' /data/misc/*/prefs/$PKG/dexpad.xml | sed 's/.*value=\"//;s/\"//')"
logcat -c
echo "--- 等 12 秒（应当隐藏指针）---"
sleep 12
echo "隐藏日志: $(logcat -d -s DexPad | grep -ac 'pointer hidden')"
logcat -c
echo "--- 推摇杆 400ms ---"
$VG stick 0 6000 400 2000 >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | grep -aE 'pointer|ptr move|restored' | tail -6
echo "helper: $(grep -aE 'POSPTR|MOUSE_REOPEN|POINTER' /data/adb/gpm/helper.log | tail -4 | tr '\n' '|')"
echo "padtest: $(logcat -d -s PadProbe | tail -3 | tr '\n' '|')"
