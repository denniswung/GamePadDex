VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
rm -f /data/local/tmp/ge2.txt
ld(){ logcat -d -s DexPad | grep -a "drag end" | tail -1; }
( timeout 2.5 getevent -lt /dev/input/event22 > /data/local/tmp/ge2.txt 2>/data/local/tmp/ge2.err & )
sleep 0.3
am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
$VG key 311 1200 300 >/dev/null 2>&1
sleep 1.5
echo "ge lines=$(wc -l < /data/local/tmp/ge2.txt) err=$(cat /data/local/tmp/ge2.err 2>/dev/null | head -2)"
grep -ac 'ABS_MT_POSITION_Y' /data/local/tmp/ge2.txt
grep -a 'ABS_MT_POSITION_Y' /data/local/tmp/ge2.txt | head -3
echo "drag: $(ld)"