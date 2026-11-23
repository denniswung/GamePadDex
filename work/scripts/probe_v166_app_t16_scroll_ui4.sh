#!/system/bin/sh
echo "TOP $(dumpsys activity activities | grep -m1 topResumedActivity)"
echo "CRASH $(logcat -d -s AndroidRuntime | grep -c com.dennis.padtest)"
sed 's/></>\n</g' /sdcard/t16v.xml > /sdcard/t16v.lines 2>/dev/null
echo "UP_ITEMS $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16v.lines | head -4 | tr '\n' ' ')"
echo "UP_PAGES $(grep -o 'text="第 [0-9] 页"' /sdcard/t16v.lines | head -3 | tr '\n' ' ')"
/data/local/tmp/vgpad stick 4 -24000 1500 0 >/dev/null 2>&1
sleep 1.5
uiautomator dump /sdcard/t16v3.xml >/dev/null 2>&1
sed 's/></>\n</g' /sdcard/t16v3.xml > /sdcard/t16v3.lines 2>/dev/null
echo "BACK_STATE $(grep -o 'text="纵向[^"]*"' /sdcard/t16v3.lines | head -1)"
echo "BACK_ITEMS $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16v3.lines | head -3 | tr '\n' ' ')"
echo DONE
