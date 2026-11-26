#!/system/bin/sh
# 禁用开关验证：gpmctl.disabled 存在 -> 不创建 socket；删除后恢复
rm -f /data/adb/gpm/gpmctl.sock
touch /data/adb/gpm/gpmctl.disabled
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
sleep 1
setsid /system/bin/sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
echo "disabled: socket=$(ls /data/adb/gpm/gpmctl.sock 2>&1) helper=$(pidof gpminput)"
rm -f /data/adb/gpm/gpmctl.disabled
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
sleep 1
setsid /system/bin/sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
echo "enabled: socket=$(ls -l /data/adb/gpm/gpmctl.sock 2>&1) helper=$(pidof gpminput)"
