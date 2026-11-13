#!/system/bin/sh
# verify: immediate UP, X+LB chord, first-key-wins when LB starts the scroll
logcat -c
/data/local/tmp/vgpad key 103 1200 800 >/dev/null 2>&1 &
sleep 1.0
echo "UP (0.2s into hold):"
logcat -d -s DexPad 2>/dev/null | grep -E 'button up|arrow' | tail -2
wait

logcat -c
/data/local/tmp/vgpad key 307 2500 600 >/dev/null 2>&1 &
sleep 1.2
/data/local/tmp/vgpad key 310 200 400 >/dev/null 2>&1 &
sleep 1.4
echo "X then LB:"
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |wheel_down started' | tail -3
wait

logcat -c
/data/local/tmp/vgpad key 310 2500 600 >/dev/null 2>&1 &
sleep 1.2
/data/local/tmp/vgpad key 307 200 400 >/dev/null 2>&1 &
sleep 1.4
echo "LB then X:"
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |wheel_down started|wheel stopped' | tail -3
wait
