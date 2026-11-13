#!/system/bin/sh
sh /data/local/tmp/dexpad_precondition.sh || exit 2
logcat -G 32M
am start -n com.dennis.dexpad/.PointerProbeActivity >/dev/null 2>&1
sleep 2
/data/local/tmp/vgpad stick 0 5000 400 1000 >/dev/null 2>&1
sleep 0.5
uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
grep -o 'text="x=[^"]*"' /sdcard/ui.xml | head -2
echo "--- center ---"
/data/local/tmp/vgpad key 317 150 3000 >/dev/null 2>&1
sleep 1
uiautomator dump /sdcard/ui2.xml >/dev/null 2>&1
grep -o 'text="x=[^"]*"' /sdcard/ui2.xml | head -2
echo "--- helper ---"
grep CENTER /data/adb/gpm/helper.log | tail -1
