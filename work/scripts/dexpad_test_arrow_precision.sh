#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}

echo "== arrow keys (dpad up) =="
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
logcat -c
/data/local/tmp/vgpad hat 0 -1 200 6000 >/dev/null 2>&1
sleep 7
logcat -d 2>/dev/null | grep -E 'arrow key|DexPadKeys' | tail -4

echo "== precision: normal stick =="
echo "before: $(read_pos)"
/data/local/tmp/vgpad stick 0 20000 800 6000 >/dev/null 2>&1
sleep 7.5
echo "after:  $(read_pos)"
sleep 1

echo "== precision: X held + stick =="
echo "before: $(read_pos)"
/data/local/tmp/vgpad key 307 5000 6000 >/dev/null 2>&1 &
sleep 0.3
/data/local/tmp/vgpad stick 0 20000 800 6500 >/dev/null 2>&1 &
wait
sleep 1
echo "after:  $(read_pos)"
