#!/system/bin/sh
echo "===== displays ====="
dumpsys display 2>/dev/null | grep -E "Display [0-9]+:|uniqueId=|mDisplayId=|FLAG_|state " | head -40
echo
echo "===== dex / desktop apps running ====="
ps -A -o PID,ARGS 2>/dev/null | grep -Ei "desktop|dex|honeyspace" | head -20
echo
echo "===== activity display state ====="
dumpsys activity activities 2>/dev/null | grep -E "Display #[0-9]+|mResumedActivity|topResumedActivity|mCurrentFocus|mFocusedApp" | head -20
echo
echo "===== dev display settings ====="
settings get global flow_pointer_is_on_dex; settings get secure flow_pointer_is_on_dex
getprop | grep -iE "dex_|desktop" | head -20
echo
echo "===== screencap display 8 ====="
screencap -p -d 8 /data/local/tmp/d8.png 2>&1; ls -l /data/local/tmp/d8.png 2>/dev/null
echo "===== screencap display 0 ====="
screencap -p -d 0 /data/local/tmp/d0.png 2>&1; ls -l /data/local/tmp/d0.png 2>/dev/null
