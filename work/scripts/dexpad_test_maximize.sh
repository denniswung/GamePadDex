#!/system/bin/sh
echo "focus:"
dumpsys window 2>/dev/null | grep -m2 'mCurrentFocus\|mFocusedApp'
for c in "117 70" "117 71" "117 19"; do
    input -d 6 keycombination $c
    sleep 1
    echo "combo $c:"
    dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1
done
