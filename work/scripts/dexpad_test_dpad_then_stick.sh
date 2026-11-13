#!/system/bin/sh
read_pos() {
    dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
}
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
input keyevent KEYCODE_WAKEUP
sleep 1
echo "pos0: $(read_pos)"
/data/local/tmp/vgpad hat 0 1 500 2600 >/dev/null 2>&1
sleep 0.5
echo "after dpad: $(read_pos)"
/data/local/tmp/vgpad stick 0 20000 700 2600 >/dev/null 2>&1
sleep 0.5
echo "pos1: $(read_pos)"
grep -E 'AX 0 0 ' /data/adb/gpm/helper.log | tail -1
logcat -d -s DexPad 2>/dev/null | grep -E 'arrow key' | tail -1
