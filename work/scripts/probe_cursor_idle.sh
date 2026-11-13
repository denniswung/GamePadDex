#!/system/bin/sh
# 观察：指针静止不动时，系统是否会自动隐藏光标
VG=/data/local/tmp/vgpad
rm -f /data/local/tmp/c1.png /data/local/tmp/c2.png
$VG key 317 100 2000 >/dev/null 2>&1   # L3 -> 光标居中
sleep 1
screencap -p /data/local/tmp/c1.png
sleep 8
screencap -p /data/local/tmp/c2.png
echo "c1=$(wc -c < /data/local/tmp/c1.png) c2=$(wc -c < /data/local/tmp/c2.png)"
echo "size=$(wm size | tr '\n' ' ')"
echo "hover=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)"
