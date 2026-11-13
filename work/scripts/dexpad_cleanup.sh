#!/system/bin/sh
# stop the old replica app from spawning its own helper and clean stray helpers
settings put secure enabled_accessibility_services 'io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService'
am force-stop com.dennis.gamepadmouse
sleep 1
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do
    echo "kill gpminput $p"
    kill -9 "$p" 2>/dev/null
done
sleep 5
echo "== remaining helpers =="
ps -A -o PID,PPID,USER,NAME | grep -E 'gpminput|gpm_dex' | grep -v grep
echo "== helper log tail =="
tail -6 /data/adb/gpm/helper.log
