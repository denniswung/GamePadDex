VG=/data/local/tmp/vgpad
RAW=/data/local/tmp/drag_raw
am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
screencap -p $RAW/T_before.png 2>/dev/null
logcat -c
$VG key 311 1500 400 >/dev/null 2>&1 &
sleep 1.1
screencap -p $RAW/T_mid.png 2>/dev/null
wait
sleep 0.8
screencap -p $RAW/T_after.png 2>/dev/null
echo "drag: $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //')"
echo "sizes: $(stat -c %s $RAW/T_before.png) $(stat -c %s $RAW/T_mid.png) $(stat -c %s $RAW/T_after.png)"