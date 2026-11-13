#!/system/bin/sh
# ensure PiliPlus windowed and screenshots around a swipe
PIL=$(am stack list 2>/dev/null | grep -oE 'taskId=[0-9]+: com.example.piliplus' | head -1 | grep -oE '[0-9]+' | head -1)
am task resize "$PIL" 1290 300 2300 1200 >/dev/null 2>&1
sleep 1
screencap -p -d 4630946213010294403 /sdcard/p1.png
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 311 300 6500 >/dev/null 2>&1
wait
sleep 1
screencap -p -d 4630946213010294403 /sdcard/p2.png
screencap -p -d 4630946213010294403 /sdcard/p3.png
ls -l /sdcard/p1.png /sdcard/p2.png /sdcard/p3.png
grep SWIPE /data/adb/gpm/helper.log | tail -1
