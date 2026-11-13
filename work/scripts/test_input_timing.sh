#!/system/bin/sh
# timing: vgpad pre=3000ms, so wait 3.2s before checking a held press
echo "== UP hold: response within 0.3s? =="
logcat -c
/data/local/tmp/vgpad key 103 2000 3000 >/dev/null 2>&1 &
sleep 3.3
logcat -d -s DexPad 2>/dev/null | grep -E 'pad key|button up|arrow' | tail -2
wait

echo "== LB hold 1.5s: wheel repeats =="
L=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad key 310 1500 3000 >/dev/null 2>&1 &
sleep 3.4
tail -n +$((L + 1)) /data/adb/gpm/helper.log | grep -c WHEEL
wait

echo "== X then LB: chord =="
logcat -c
/data/local/tmp/vgpad key 307 2500 3000 >/dev/null 2>&1 &
sleep 3.3
/data/local/tmp/vgpad key 310 200 3000 >/dev/null 2>&1 &
sleep 3.4
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |wheel_down started' | tail -2
wait

echo "== LB then X: first key wins =="
logcat -c
/data/local/tmp/vgpad key 310 2500 3000 >/dev/null 2>&1 &
sleep 3.3
/data/local/tmp/vgpad key 307 200 3000 >/dev/null 2>&1 &
sleep 3.4
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |wheel_down started|wheel stopped' | tail -3
wait
