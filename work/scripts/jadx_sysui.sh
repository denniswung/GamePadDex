#!/bin/bash
set -u
export JAVA_HOME="$HOME/tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
cd "$HOME"
echo "SYS=$(pwd)" > /tmp/sysui_marker
"$HOME/tools/jadx-1.5.0/bin/jadx" -d "$HOME/sysui_out" --no-res -j 8 "$HOME/sysui_x/classes2.dex" 2>&1 | tail -3
echo "=== files ==="
ls "$HOME/sysui_out/sources/com/android/systemui/dextouchpad/" 2>/dev/null | head
echo "=== scroll / inject hits ==="
grep -rln -e "ACTION_SCROLL" -e "injectInputEvent" -e "AXIS_VSCROLL" "$HOME/sysui_out/sources/com/android/systemui/dextouchpad/" 2>/dev/null
