#!/system/bin/sh
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
echo "base: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "== X double tap =="
logcat -c
/data/local/tmp/vgpad double 307 60 90 2600 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad 2>/dev/null | grep -E 'double|switch|single|recents' | tail -5
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "== X single tap =="
logcat -c
/data/local/tmp/vgpad key 307 80 2600 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad 2>/dev/null | grep -E 'single|recents' | tail -4
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "== X+LB combo still works =="
logcat -c
/data/local/tmp/vgpad combo 307 310 600 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix 4|single' | tail -3
