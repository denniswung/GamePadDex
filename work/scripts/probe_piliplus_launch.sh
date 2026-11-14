#!/system/bin/sh
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake; sleep 1
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c
echo "=== 显式启动 com.example.piliplus/.MainActivity ==="
am start -n com.example.piliplus/.MainActivity 2>&1 | head -4
sleep 3
echo "top: $(top)"
echo "--- crash ---"
logcat -b crash -d 2>/dev/null | grep -A8 'piliplus' | head -20
echo "--- 最近进程 ---"
ps -A -o PID,NAME 2>/dev/null | grep -i pili
echo "--- logcat 最近 error ---"
logcat -d 2>/dev/null | grep -iE 'piliplus' | tail -12
