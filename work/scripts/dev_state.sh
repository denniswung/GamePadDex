#!/system/bin/sh
echo "===== A. app log (MouseService) ====="
logcat -d -s MouseService:V MouseService_GlobalKey:V 2>/dev/null | tail -60
echo
echo "===== B. overlay windows of gamepadmouse ====="
dumpsys window windows 2>/dev/null | grep -E "Window #|gamepadmouse|mOwnerUid|ty=|ty=2032|fl=|mAttrs" | grep -B2 -A6 gamepadmouse | head -60
echo
echo "===== C. window list (names + types) ====="
dumpsys window windows 2>/dev/null | grep -E "^  Window #|mAttrs=\{" | grep -A1 "Window #" | grep -E "gamepadmouse" -A1 | head -40
echo
echo "===== D. xbox input device detail ====="
dumpsys input 2>/dev/null | grep -B2 -A12 "Xbox" | head -40
echo
echo "===== E. screen/display power state ====="
dumpsys power 2>/dev/null | grep -E "mWakefulness=|Display Power" | head -6
dumpsys display 2>/dev/null | grep -E "mDisplayId|DisplayDeviceInfo" | grep -oE 'uniqueId="[^"]*"|mDisplayId=[0-9]+|state [A-Z]+' | head -12
