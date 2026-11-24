VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
rm -f /data/local/tmp/dd.bin
( timeout -s INT 2.5 dd if=/dev/input/event22 of=/data/local/tmp/dd.bin bs=24 count=600 2>/data/local/tmp/dd.err & )
sleep 0.3
am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
$VG key 311 1200 300 >/dev/null 2>&1
sleep 1.6
echo "bytes=$(stat -c %s /data/local/tmp/dd.bin 2>/dev/null) err=$(head -2 /data/local/tmp/dd.err 2>/dev/null)"
echo "records=$(( $(stat -c %s /data/local/tmp/dd.bin 2>/dev/null) / 24 ))"
od -An -tu4 -w24 /data/local/tmp/dd.bin 2>/dev/null | head -3