#!/system/bin/sh
PAD=com.dennis.padtest
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
echo "=== ProbeActivity 启动输出 ==="
am start -n $PAD/.ui.ProbeActivity 2>&1 | head -4
sleep 2; echo "top=$(top)"
echo "=== CursorTestActivity ==="
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity 2>&1 | head -4
sleep 2; echo "top=$(top)"
echo "=== manifest 里声明的 activity ==="
dumpsys package $PAD 2>/dev/null | grep -A2 'com.dennis.padtest' | grep -E 'Activity' | head -12
