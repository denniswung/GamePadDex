#!/system/bin/sh
# put the pointer in the top-left corner, then press L3 and check where it lands
DEV=$(getevent -pl 2>/dev/null | grep -B2 'Gamepad Mouse Pointer' | grep 'add device' | grep -o '/dev/input/event[0-9]*')
echo "dev=$DEV"
sendevent $DEV 2 0 -5000
sendevent $DEV 2 1 -5000
sendevent $DEV 0 0 0
sleep 0.3
echo "before: $(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=[^]]*]' | head -1)"
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -3
echo "after: $(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=[^]]*]' | head -1)"
