#!/system/bin/sh
dumpsys input 2>/dev/null | grep -n -i -E 'Gamepad.*Pointer|Gamepad Absolute' | head -10
echo "--- 设备块 ---"
dumpsys input 2>/dev/null | awk '/Gamepad Absolute/,/^  [0-9]+: /' | head -30
