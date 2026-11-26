#!/system/bin/sh
# restart helper with new binary and ensure control socket
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
rm -f /data/adb/gpm/gpmctl.disabled
sleep 1
setsid /system/bin/sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1
sleep 2
echo "helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad)"
ls -l /data/adb/gpm/gpmctl.sock
ls -ld /data/adb/gpm
