#!/system/bin/sh
shot() { screencap -p -d 4632669078734337540 /sdcard/$1.png; ls -l /sdcard/$1.png | awk '{print $5, $8}'; }
echo "base:"; shot s0
echo "scroll1:"; /data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1; sleep 1; shot s1
echo "scroll2:"; /data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1; sleep 1; shot s2
echo "swipe right (X+RB):"; /data/local/tmp/vgpad combo 307 311 600 2600 >/dev/null 2>&1; sleep 1; shot s3
echo "scroll3:"; /data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1; sleep 1; shot s4
echo "swipe left (X+LB):"; /data/local/tmp/vgpad combo 307 310 600 2600 >/dev/null 2>&1; sleep 1; shot s5
echo "scroll4:"; /data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1; sleep 1; shot s6
grep SWIPE /data/adb/gpm/helper.log | tail -4
