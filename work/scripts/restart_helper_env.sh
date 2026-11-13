#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -f 'gpm_dex/service.sh'
pkill -f ScrollInject
sleep 2
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 9
echo "== processes =="
ps -A -o PID,NAME | grep -E 'gpminput|ScrollInject' | grep -v grep
echo "== helper log =="
tail -8 /data/local/tmp/gpm-module.log
