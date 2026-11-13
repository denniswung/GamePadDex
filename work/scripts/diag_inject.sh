#!/system/bin/sh
chmod 644 /data/adb/gpm/inject.dex
ls -lZ /data/adb/gpm/inject.dex
echo "=== try 1: CLASSPATH env ==="
echo "10 20 3" | CLASSPATH=/data/adb/gpm/inject.dex app_process /system/bin ScrollInject 2>&1 | head -5
echo "=== try 2: -Djava.class.path + nice-name ==="
echo "10 20 3" | app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin --nice-name=gpm-scroll ScrollInject 2>&1 | head -8
echo "=== avc denials ==="
dmesg 2>/dev/null | grep -i avc | tail -3
echo "=== logcat ==="
logcat -d -b crash 2>/dev/null | tail -6
logcat -d 2>/dev/null | grep -iE "app_process|ScrollInject|injectInputEvent" | tail -5
