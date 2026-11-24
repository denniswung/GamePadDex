VG=/data/local/tmp/vgpad
RAW=/data/local/tmp/drag_raw
am force-stop com.example.piliplus >/dev/null 2>&1
am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.5
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
screencap -p $RAW/P0.png 2>/dev/null
for i in 1 2 3; do
  logcat -c
  $VG key 311 500 400 >/dev/null 2>&1
  sleep 0.8
  screencap -p $RAW/P$i.png 2>/dev/null
  echo "P$i drag: $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //')"
done
echo "sizes: $(stat -c %s $RAW/P0.png) $(stat -c %s $RAW/P1.png) $(stat -c %s $RAW/P2.png) $(stat -c %s $RAW/P3.png)"