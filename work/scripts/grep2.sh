#!/bin/bash
set -u
O="$HOME/sysui_out/sources/com/android/systemui/dextouchpad"
echo "=== TouchpadFragment / View files ==="
find "$O" -name "*.java" | sed "s|$O/||" | sort | head -40
echo
echo "=== grep interesting tokens ==="
for t in "MotionEvent.obtain" "SOURCE_MOUSE" "inject" "sendPointerEvent" "dispatchPointer" "AXIS_X" "pointer"; do
  echo "--- $t ---"
  grep -rl "$t" "$O" 2>/dev/null | sed "s|$O/||" | head -6
done
