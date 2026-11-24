am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.2
cmd statusbar collapse
/data/local/tmp/vgpad key 317 100 800 >/dev/null 2>&1
sleep 1.0
: > /data/adb/gpm/helper.log
/data/local/tmp/vgpad key 310 1500 400 >/dev/null 2>&1
sleep 1.2
grep -a '^SWIPE ' /data/adb/gpm/helper.log