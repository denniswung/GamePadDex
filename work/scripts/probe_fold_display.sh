#!/system/bin/sh
echo "=== mCurrentFocus ==="
dumpsys window 2>/dev/null | grep mCurrentFocus | head -3
echo "=== app 任务所在 display ==="
dumpsys activity activities 2>/dev/null | grep -m1 'CursorTestActivity' 
echo "=== display 列表(简称) ==="
dumpsys display 2>/dev/null | grep -oE 'uniqueId="[^"]*", [0-9]+ x [0-9]+' | head -4
dumpsys display 2>/dev/null | grep -oE 'state [A-Z]+' | head -6
echo "=== 折叠 ==="
settings get global device_folded
echo "=== 覆盖分辨率 ==="
wm size
wm size reset 2>&1
sleep 0.5
wm size
