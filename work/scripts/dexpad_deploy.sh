#!/system/bin/sh
# Deploy the updated helper wiring for com.dennis.dexpad and (re)start everything.
MOD=/data/adb/modules/gpm_dex
APP=com.dennis.dexpad
DATA=/data/user/0/$APP
SOCK=$DATA/files/gpm.sock

echo "== stop old supervisor + helper =="
pkill -f 'gpm_dex/service.sh' 2>/dev/null
sleep 1
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do
    kill -9 "$p" 2>/dev/null
done
rm -f "$SOCK" /data/adb/gpm/helper.lock /data/adb/gpm/service.pid

echo "== ensure app socket dir =="
UID_APP=$(stat -c %u "$DATA" 2>/dev/null)
mkdir -p "$DATA/files"
[ -n "$UID_APP" ] && chown "$UID_APP:$UID_APP" "$DATA/files"
restorecon -R "$DATA/files" 2>/dev/null
ls -ld "$DATA" "$DATA/files"

echo "== start supervisor =="
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 5
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
ls -l "$SOCK" 2>&1

echo "== start engine service =="
am start-foreground-service -n $APP/.EngineService
sleep 3
echo "== engine logs =="
logcat -d -s DexPad:I DexPadLink:I 2>/dev/null | tail -12
