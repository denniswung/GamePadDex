VG=/data/local/tmp/vgpad
am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 1
: > /data/adb/gpm/helper.log
$VG key 311 1000 300 >/dev/null 2>&1; sleep 1.2
echo "== helper DRAG lines =="
grep -a 'DRAG' /data/adb/gpm/helper.log
echo "== TOUCH/other lines =="
grep -a -c 'TOUCH' /data/adb/gpm/helper.log