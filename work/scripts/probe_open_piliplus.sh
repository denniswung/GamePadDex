#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1

echo "=== piliplus 包信息 ==="
pm list packages 2>/dev/null | grep -i pili
dumpsys package com.example.piliplus 2>/dev/null | grep -m3 -E 'versionName|android.intent.action.MAIN|LAUNCHER' | head -5
echo "dumpsys 里可启动入口："
cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER com.example.piliplus 2>&1 | tail -2

echo
echo "=== 用 shell 域 am start 对照 ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.example.piliplus >/dev/null 2>&1
sleep 2.5
echo "after shell am start: $(top)"

echo
echo "=== 用助手 w 命令（helper 域）==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
hcmd "w com.example.piliplus"
sleep 2.5
echo "helper: $(grep -aE 'OPEN_APP' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "after helper w: $(top)"
