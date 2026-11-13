#!/system/bin/sh
shot() { screencap -p -d 4632669078734337540 /sdcard/$1.png; ls -l /sdcard/$1.png | awk '{print $5}'; }
echo "hold scroll 2s:"
/data/local/tmp/vgpad stick 4 20000 2000 2600 >/dev/null 2>&1 &
sleep 2.7; shot h1
sleep 0.5; shot h2
sleep 0.5; shot h3
sleep 0.5; shot h4
wait
echo "horizontal swipes twice:"
grep SWIPE /data/adb/gpm/helper.log | tail -1
/data/local/tmp/vgpad combo 307 311 600 2600 >/dev/null 2>&1
sleep 0.5
/data/local/tmp/vgpad combo 307 311 600 2600 >/dev/null 2>&1
sleep 1
grep SWIPE /data/adb/gpm/helper.log | tail -2
echo "wheel hold LB 1.5s:"
/data/local/tmp/vgpad hold 310 1500 >/dev/null 2>&1 &
sleep 0.3; shot w1; sleep 1.5; shot w2; wait
