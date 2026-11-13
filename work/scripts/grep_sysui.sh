#!/bin/bash
set -u
O="$HOME/sysui_out/sources"
echo "=== dextouchpad subpackages ==="
find "$O/com/android/systemui/dextouchpad" -maxdepth 2 -type d | sed "s|$O/||"
echo
echo "=== files mentioning injectInputEvent ==="
grep -rl "injectInputEvent" "$O" 2>/dev/null | sed "s|$O/||" | head -20
echo
echo "=== files mentioning AXIS_VSCROLL ==="
grep -rl "AXIS_VSCROLL" "$O" 2>/dev/null | sed "s|$O/||" | head -20
echo
echo "=== files mentioning ACTION_SCROLL ==="
grep -rl "ACTION_SCROLL" "$O" 2>/dev/null | sed "s|$O/||" | head -20
echo
echo "=== touchpad dir contents ==="
ls "$O/com/android/systemui/dextouchpad/touchpad/" 2>/dev/null | head -20
ls "$O/com/android/systemui/dextouchpad/manager/" 2>/dev/null | head -20
