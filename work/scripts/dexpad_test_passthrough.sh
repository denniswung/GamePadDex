#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
input keyevent KEYCODE_WAKEUP
sleep 1
echo "pos0: $(read_pos)"
logcat -c
echo "== dpad down =="
/data/local/tmp/vgpad hat 0 1 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'native passthrough|arrow key' | tail -4
grep -E 'GONE|GRABBED' /data/adb/gpm/helper.log | tail -2
echo "== dpad down again (should be native, no new arrow log) =="
logcat -c
/data/local/tmp/vgpad hat 0 -1 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'arrow key|native passthrough' | tail -2
echo "== left stick (back to mouse) =="
logcat -c
/data/local/tmp/vgpad stick 0 20000 700 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'native passthrough|mouse mode' | tail -2
grep -E 'GONE|GRABBED' /data/adb/gpm/helper.log | tail -2
echo "pos1: $(read_pos)"
