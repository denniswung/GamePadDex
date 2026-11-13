#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "center:"
/data/local/tmp/vgpad key 317 300 3000 >/dev/null 2>&1
sleep 4
echo "base: $(read_pos)"
echo "== normal stick 800ms =="
/data/local/tmp/vgpad stick 0 20000 800 5000 >/dev/null 2>&1 &
sleep 4.9
echo "before: $(read_pos)"
sleep 2
echo "after:  $(read_pos)"
sleep 1
echo "== precision X+stick 800ms =="
echo "prec base: $(read_pos)"
/data/local/tmp/vgpad key 307 4000 5000 >/dev/null 2>&1 &
sleep 0.3
/data/local/tmp/vgpad stick 0 20000 800 5200 >/dev/null 2>&1 &
sleep 4.9
echo "before: $(read_pos)"
sleep 2
echo "after:  $(read_pos)"
