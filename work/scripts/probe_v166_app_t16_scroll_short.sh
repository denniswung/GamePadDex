#!/system/bin/sh
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
dump(){ uiautomator dump /sdcard/t16s.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/t16s.xml > /sdcard/t16s.lines; }
wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse >/dev/null 2>&1
dump
echo "BEFORE $(grep -o 'text="纵向[^"]*"' /sdcard/t16s.lines | head -1)"
$VG stick 4 24000 400 0 >/dev/null 2>&1
sleep 1.2
dump
echo "AFTER400 $(grep -o 'text="纵向[^"]*"' /sdcard/t16s.lines | head -1)"
echo "ITEMS $(grep -o 'text="列表项 #[0-9]*"' /sdcard/t16s.lines | head -3 | tr '\n' ' ')"
echo "PAGE1 $(grep -o 'text="第 1 页".\{0,80\}' /sdcard/t16s.lines | head -1 | grep -o 'bounds="[^"]*"')"
echo DONE
