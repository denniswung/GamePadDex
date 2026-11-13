#!/system/bin/sh
# START twice with generous gaps, printing the top activity after each press
echo "start: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 4
echo "after1: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 4
echo "after2: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 4
echo "after3: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "== switch log =="
grep SWITCH /data/adb/gpm/helper.log | tail -4
