#!/system/bin/sh
echo "== freecess files =="
find /data/system /data/misc /data/local -iname '*freecess*' 2>/dev/null | head -20
echo "== adj =="
PID=$(pidof com.dennis.dexpad | awk '{print $1}')
dumpsys activity processes 2>/dev/null | grep -A40 "ProcessRecord{.*$PID:com.dennis.dexpad" | grep -E 'curAdj|setAdj|curProcState|frozen|adjType|hasForeground' | head -8
echo "== logcat freecess =="
logcat -d 2>/dev/null | grep -i freecess | tail -8
