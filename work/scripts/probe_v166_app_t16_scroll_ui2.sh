#!/system/bin/sh
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
dump(){ uiautomator dump /sdcard/t16ui2.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/t16ui2.xml > /sdcard/t16ui2.lines; }
wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse >/dev/null 2>&1
dump
echo "START: $(grep -o 'text="[^"]*offset[^"]*"' /sdcard/t16ui2.lines | head -3 | tr '\n' ' ')"
$VG stick 4 -24000 1500 0 >/dev/null 2>&1
sleep 1.5
dump
echo "AFTER_V: $(grep -o 'text="[^"]*offset[^"]*"' /sdcard/t16ui2.lines | head -3 | tr '\n' ' ')"
echo "AFTER_V2: $(grep -o 'text="纵向[^"]*"' /sdcard/t16ui2.lines | head -2 | tr '\n' ' ')"
echo "VISIBLE_ITEMS: $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16ui2.lines | head -3 | tr '\n' ' ')"
$VG stick 3 24000 1500 0 >/dev/null 2>&1
sleep 1.5
dump
echo "AFTER_H: $(grep -o 'text="[^"]*offset[^"]*"' /sdcard/t16ui2.lines | head -3 | tr '\n' ' ')"
echo "AFTER_H2: $(grep -o 'text="横向[^"]*"' /sdcard/t16ui2.lines | head -2 | tr '\n' ' ')"
echo DONE
