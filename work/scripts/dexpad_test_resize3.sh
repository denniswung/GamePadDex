#!/system/bin/sh
TID=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed -n 's/.* t\([0-9]*\)}.*/\1/p')
echo "tid=$TID"
am task resize "$TID" 0 0 2560 1600 2>&1
sleep 1
dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1
