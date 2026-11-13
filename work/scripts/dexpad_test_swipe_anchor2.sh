#!/system/bin/sh
PIL=$(am stack list 2>/dev/null | grep -oE 'taskId=[0-9]+: com.example.piliplus' | head -1 | grep -oE '[0-9]+' | head -1)
echo "pili task=$PIL"
am task resize "$PIL" 1290 300 2300 1200 >/dev/null 2>&1
sleep 1
dumpsys window windows 2>/dev/null | grep -o 'piliplus.MainActivity, frame=\[Rect([^)]*)\]' | head -1
sendevent /dev/input/event19 2 0 -2000
sendevent /dev/input/event19 2 1 -2000
sendevent /dev/input/event19 0 0 0
sleep 0.5
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 311 300 6500 >/dev/null 2>&1
wait
grep SWIPE /data/adb/gpm/helper.log | tail -2
