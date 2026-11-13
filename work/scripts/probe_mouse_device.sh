#!/system/bin/sh
PKG=com.dennis.dexpad
mice() { dumpsys input 2>/dev/null | grep -cE 'GamepadMouse|Virtual Mouse|Gamepad Mouse'; }
echo "before idle mice-lines=$(mice)"
sleep 10
echo "after  idle mice-lines=$(mice)"
/data/local/tmp/vgpad stick 0 20000 300 2000 >/dev/null 2>&1
sleep 1
echo "after stick mice-lines=$(mice)"
echo "--- devices ---"
dumpsys input 2>/dev/null | grep -E 'Gamepad|Mouse' | head -6
