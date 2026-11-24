VG=/data/local/tmp/vgpad
RAW=/data/local/tmp/drag_raw
am force-stop com.example.piliplus >/dev/null 2>&1
am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.5
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
screencap -p $RAW/P_before.png 2>/dev/null
logcat -c
$VG key 311 1500 400 >/dev/null 2>&1 &
sleep 1.15
screencap -p $RAW/P_mid12.png 2>/dev/null
wait
sleep 0.8
screencap -p $RAW/P_after.png 2>/dev/null
echo "drag: $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //')"
echo "start: $(logcat -d -s DexPad | grep -a 'drag start' | tail -1 | sed 's/^.*DexPad *: //')"