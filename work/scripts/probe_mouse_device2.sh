#!/system/bin/sh
kdev() { grep -c 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null; }
idev() { dumpsys input 2>/dev/null | grep -c 'Gamepad Mouse Pointer'; }
echo "t0: kernel=$(kdev) framework=$(idev)"
sleep 10
echo "t10(idle): kernel=$(kdev) framework=$(idev)"
/data/local/tmp/vgpad stick 0 20000 300 2000 >/dev/null 2>&1
sleep 1.2
echo "t11(stick): kernel=$(kdev) framework=$(idev)"
grep -a 'POINTER' /data/adb/gpm/helper.log | tail -3
