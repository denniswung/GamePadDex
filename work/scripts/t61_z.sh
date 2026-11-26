#!/system/bin/sh
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
uiautomator dump /sdcard/t61z.xml >/dev/null 2>&1
grep -a -o 'text="[^"]*"' /sdcard/t61z.xml | sed -n '9,20p'
echo '--- after drag ---'
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
sleep 0.1
timeout 5 "$G" "$S" m 0 0 -300 240 >/dev/null 2>&1
sleep 0.6
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 0.8
uiautomator dump /sdcard/t61z2.xml >/dev/null 2>&1
grep -a -o 'text="[^"]*"' /sdcard/t61z2.xml | sed -n '9,20p'
