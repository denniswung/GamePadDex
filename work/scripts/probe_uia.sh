#!/system/bin/sh
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
t0=$(date +%s%N)
uiautomator dump --compressed /sdcard/f.xml >/dev/null 2>&1
t1=$(date +%s%N)
echo "dump_ms=$(( (t1-t0)/1000000 ))"
echo "scrollable_count=$(grep -o 'scrollable="true"' /sdcard/f.xml | wc -l)"
echo "--- sample nodes ---"
tr '>' '\n' < /sdcard/f.xml | grep 'scrollable="true"' | head -4
echo "--- size ---"
ls -l /sdcard/f.xml | awk '{print $5}'
