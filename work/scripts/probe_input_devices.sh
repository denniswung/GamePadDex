#!/system/bin/sh
echo "=== /proc/bus/input/devices (Gamepad) ==="
grep -A5 -i 'Gamepad' /proc/bus/input/devices | grep -E 'Name|Handlers|EV=|ABS=' | head -30
echo
echo "=== dumpsys input: device list ==="
dumpsys input 2>/dev/null | grep -iE '^\s+[0-9]+: |Name:|Sources:|Classes:|Keyboard Type|Pointer' | head -40
