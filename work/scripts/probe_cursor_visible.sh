#!/system/bin/sh
VG=/data/local/tmp/vgpad
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
$VG key 317 100 2000 >/dev/null 2>&1
sleep 1
$VG stick 0 20000 300 0 >/dev/null 2>&1
sleep 1
screencap -p /data/local/tmp/s1.png
H=$(dumpsys input 2>/dev/null | grep -m1 -o 'at ([0-9.]*, [0-9.]*)')
echo "hover=$H"
echo "size=$(wc -c < /data/local/tmp/s1.png)"
