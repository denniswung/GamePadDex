#!/system/bin/sh
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad key 317 300 2600 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -1
dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
/data/local/tmp/vgpad key 307 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'button x|recents on|double' | tail -3
