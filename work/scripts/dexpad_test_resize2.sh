#!/system/bin/sh
TID=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed -n 's/.* t\([0-9]*\)}.*/\1/p')
echo "tid=$TID"
am task resize "$TID" 0 0 2560 1544 2>&1
sleep 1
echo "after: $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
am task resize "$TID" 0 0 1280 1544 2>&1
sleep 1
echo "half: $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
