VG=/data/local/tmp/vgpad
am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 1
logcat -c
$VG key 311 800 300 >/dev/null 2>&1; sleep 1.2
echo "== PadProbe tail =="
logcat -d -s PadProbe 2>/dev/null | tail -8
echo "== drag events =="
logcat -d -s DexPad 2>/dev/null | grep -a 'drag ' | tail -3