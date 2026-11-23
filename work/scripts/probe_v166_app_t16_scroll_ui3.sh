#!/system/bin/sh
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
dump(){ uiautomator dump /sdcard/t16v.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/t16v.xml > /sdcard/t16v.lines; }
wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse >/dev/null 2>&1
dump
echo "START $(grep -o 'text="纵向[^"]*"' /sdcard/t16v.lines | head -1)"
echo "START_ITEMS $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16v.lines | head -2 | tr '\n' ' ')"
$VG stick 4 24000 1500 0 >/dev/null 2>&1
sleep 1.5
dump
echo "AFTER_UP $(grep -o 'text="纵向[^"]*"' /sdcard/t16v.lines | head -1)"
echo "AFTER_ITEMS $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16v.lines | head -2 | tr '\n' ' ')"
echo "MIX $(grep -o 'text="混合[^"]*"' /sdcard/t16v.lines | head -1)"
echo DONE
