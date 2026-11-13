#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
logcat -c
L1=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad key 307 6000 2600 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad hat 0 1 300 2600 >/dev/null 2>&1
sleep 1
L2=$(wc -l < /data/adb/gpm/helper.log)
echo "== helper new lines =="
tail -n $((L2-L1+1)) /data/adb/gpm/helper.log | grep -E 'AX 0 16|KEY 0 307|PAD|KEYON' | tail -8
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -iE 'mix|volume|native' | tail -4
