#!/system/bin/sh
logcat -c
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
echo "== helper tail =="
tail -n 5 /data/adb/gpm/helper.log
echo "== engine arrow count =="
logcat -d -s DexPad 2>/dev/null | grep -c 'arrow key'
