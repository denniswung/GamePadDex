VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
rm -f /data/local/tmp/ge4.txt /data/local/tmp/ge5.txt
( timeout -s INT 2.5 getevent -t /dev/input/event22 > /data/local/tmp/ge4.txt 2>&1 & )
( stdbuf -o0 getevent -t /dev/input/event22 > /data/local/tmp/ge5.txt 2>&1 & )
sleep 0.3
am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
$VG key 311 1200 300 >/dev/null 2>&1
sleep 1.5
pkill -f 'getevent' 2>/dev/null
sleep 0.5
echo "ge4 lines=$(wc -l < /data/local/tmp/ge4.txt) y=$(grep -ac ABS_MT_POSITION_Y /data/local/tmp/ge4.txt)"
echo "ge5 lines=$(wc -l < /data/local/tmp/ge5.txt) y=$(grep -ac ABS_MT_POSITION_Y /data/local/tmp/ge5.txt)"
head -3 /data/local/tmp/ge4.txt