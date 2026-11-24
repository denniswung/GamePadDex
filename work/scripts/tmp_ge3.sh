VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
rm -f /data/local/tmp/ge3.txt
( timeout 2.5 getevent -t /dev/input/event22 > /data/local/tmp/ge3.txt 2>&1 & )
sleep 0.3
am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
$VG key 311 1200 300 >/dev/null 2>&1
sleep 1.5
echo "lines=$(wc -l < /data/local/tmp/ge3.txt)"
grep -a 'ABS_MT_POSITION_Y' /data/local/tmp/ge3.txt | head -3
echo "ycount=$(grep -ac 'ABS_MT_POSITION_Y' /data/local/tmp/ge3.txt)"