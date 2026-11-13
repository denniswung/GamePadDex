#!/system/bin/sh
# hold ALT for 400ms and press TAB in the middle (simulates a real Alt+Tab)
echo "before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
input -d 6 keyevent --duration 400 57 &
sleep 0.15
input -d 6 keyevent 61
wait
sleep 1
echo "after: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
