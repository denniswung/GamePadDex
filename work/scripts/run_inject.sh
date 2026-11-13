#!/system/bin/sh
chmod 644 /data/adb/gpm/inject.dex
echo "=== run injector (single scroll) ==="
echo "1280 800 3" | app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin ScrollInject 2>&1 | head -12
echo "=== exit=$? ==="
echo "=== logcat runtime ==="
logcat -d 2>/dev/null | grep -A3 "ScrollInject" | tail -12
