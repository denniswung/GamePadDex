#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}
echo "== normal =="
/data/local/tmp/vgpad key 317 300 3000 >/dev/null 2>&1
sleep 1
echo "A $(read_pos)"
/data/local/tmp/vgpad stick 0 20000 800 4000 >/dev/null 2>&1
echo "B $(read_pos)"
echo "== precision (X + stick) =="
/data/local/tmp/vgpad key 317 300 3000 >/dev/null 2>&1
sleep 1
echo "C $(read_pos)"
/data/local/tmp/vgpad key 307 4000 4000 >/dev/null 2>&1 &
sleep 0.3
/data/local/tmp/vgpad stick 0 20000 800 4300 >/dev/null 2>&1
wait
echo "D $(read_pos)"
