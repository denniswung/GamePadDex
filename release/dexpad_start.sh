#!/system/bin/sh
# Start the DeX gamepad root helper on the com.dennis.dexpad socket.
#
# This device runs KernelSU in late-load mode, so module boot scripts are not
# executed at reboot; run this once after every reboot (adb is root here):
#
#   adb shell sh /data/local/tmp/dexpad_start.sh
#
# It is also what the KSU module's service.sh does at boot on setups where
# module scripts do run.

MOD=/data/adb/modules/gpm_dex
APP=com.dennis.dexpad
DATA=/data/user/0/$APP
SOCK=$DATA/files/gpm.sock

pkill -f 'gpm_dex/service.sh --supervisor' 2>/dev/null
sleep 1
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do
    kill -9 "$p"
done
rm -f "$SOCK" /data/adb/gpm/helper.lock

UID_APP=$(stat -c %u "$DATA" 2>/dev/null)
mkdir -p "$DATA/files"
[ -n "$UID_APP" ] && chown "$UID_APP:$UID_APP" "$DATA/files"
restorecon -R "$DATA/files" 2>/dev/null

setsid /system/bin/sh "$MOD/service.sh" --supervisor >/dev/null 2>&1 </dev/null &
sleep 4
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
ls -l "$SOCK" 2>&1

# keep the app out of Doze app-standby so the foreground engine survives idle
dumpsys deviceidle whitelist +$APP >/dev/null 2>&1
cmd appops set $APP RUN_IN_BACKGROUND allow >/dev/null 2>&1

am start-foreground-service -n $APP/.EngineService >/dev/null 2>&1
echo "engine requested"
