#!/system/bin/sh
VG=/data/local/tmp/vgpad
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

echo "=== A) X 按住 + 左摇杆：应取消 X 的单键（不出左键） ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG holdstick 307 0 15000 600 2000 >/dev/null 2>&1
sleep 1.2
echo "  click_down=$(logcat -d -s PadProbe | grep -c 'MOUSE/click-down') home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'cancel|single|ptr move' | sed 's/^.*DexPad  : /    /' | head -4

echo "=== B) Y 按住 + L3：应是电源（Y+L3），且不出 Home ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG combo 308 317 500 2000 >/dev/null 2>&1
sleep 1.5
echo "  power=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'POWER') home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
logcat -d -s DexPad | grep -E 'mix 9|power|home|single' | sed 's/^.*DexPad  : /    /' | head -5
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1

echo "=== C) 单击 Y（无摇杆）：应 Home ==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.0
echo "  home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
