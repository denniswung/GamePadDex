#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}
am start --display 6 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "base: $(read_pos)"
logcat -c
/data/local/tmp/vgpad hat 0 -1 300 2600 >/dev/null 2>&1
sleep 1
echo "after up: $(read_pos)"
logcat -d -s DexPad 2>/dev/null | grep -E 'arrow key' | tail -1
/data/local/tmp/vgpad hat 0 1 300 2600 >/dev/null 2>&1
sleep 1
echo "after down: $(read_pos)"
/data/local/tmp/vgpad hat -1 0 300 2600 >/dev/null 2>&1
sleep 1
echo "after left: $(read_pos)"
/data/local/tmp/vgpad hat 1 0 300 2600 >/dev/null 2>&1
sleep 1
echo "after right: $(read_pos)"
