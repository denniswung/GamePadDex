#!/system/bin/sh
for f in uia uia2 uia3; do
  echo "--- $f ---"
  cat /data/adb/gpm/$f.log 2>/dev/null | tail -3
done
echo "--- daemon ns check ---"
echo "apex visible: $(ls /apex/com.android.art/lib64/libnativeloader.so 2>/dev/null | wc -l)"
echo "su -M from shell: $(su -M -c 'echo ok' 2>&1 | tail -1)"
echo "nsenter from shell: $(nsenter -t 1 -m -- /system/bin/echo ok 2>&1 | tail -1)"
