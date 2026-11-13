#!/system/bin/sh
# install the KernelSU module tree on the device and start it now (no reboot)
MOD=/data/adb/modules/gpm_dex
rm -rf $MOD
mkdir -p $MOD
cp -f /data/local/tmp/gpm_module/module.prop    $MOD/
cp -f /data/local/tmp/gpm_module/service.sh     $MOD/
cp -f /data/local/tmp/gpm_module/post-fs-data.sh $MOD/
cp -f /data/local/tmp/gpm_module/gpminput       $MOD/
cp -f /data/local/tmp/gpm_module/inject.dex     $MOD/
chmod 755 $MOD/service.sh $MOD/post-fs-data.sh $MOD/gpminput
chmod 644 $MOD/module.prop $MOD/inject.dex
ls -l $MOD
echo "== stop the old daemon, start through the module script =="
pkill -f ScrollInject 2>/dev/null
killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/com.dennis.gamepadmouse/files/gpm.sock
setsid sh $MOD/service.sh >/data/local/tmp/module.log 2>&1 </dev/null &
sleep 5
echo "== daemon =="
ps -A | grep -c gpminput
ls -l /data/adb/gpm/ 2>&1 | head -4
tail -2 /data/local/tmp/module.log
