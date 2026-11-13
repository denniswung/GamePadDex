#!/system/bin/sh
echo "task: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
for c in "117 69" "117 71" "117 72" "117 70"; do
    input -d 6 keycombination $c
    sleep 1
    echo "combo $c -> $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
done
echo "== resize test =="
TID=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -o ' t[0-9]*' | tr -d ' t')
echo "tid=$TID"
am task resize "$TID" 0 0 2560 1544 2>&1
sleep 1
echo "after resize: $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
