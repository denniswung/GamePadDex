#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
RPT=/sdcard/Android/data/$PAD/files/auto-report.json
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
echo "mode=$(grep -oE 'name=\"mode_on\" value=\"[a-z]+\"' /data/misc/*/prefs/$PKG/dexpad.xml | sed 's/.*value=\"//;s/\"//')"
echo "engine pid=$(pidof $PKG) helper pid=$(pidof gpminput)"
logcat -c
rm -f "$RPT"
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.AutoTestActivity >/dev/null 2>&1
sleep 2.5
echo "top=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.5
: > /data/adb/gpm/helper.log
$VG stick 0 15000 500 2000 >/dev/null 2>&1
sleep 0.5
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "报告: $(cat "$RPT" 2>/dev/null | tr -d '\n ' | head -c 300)"
echo
echo "helper: $(grep -aE 'GRABBED|DEV ' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "engine: $(logcat -d -s DexPad | grep -aE 'button a|left button|ptr move|A pressed' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
