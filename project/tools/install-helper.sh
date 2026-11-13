#!/system/bin/sh
# install/refresh the root helper + boot script on the device
set -e
PKG=com.dennis.gamepadmouse
mkdir -p /data/adb/gpm
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
chmod 755 /data/adb/gpm/gpminput
mkdir -p /data/adb/service.d
cp -f /data/local/tmp/99-gpm-helper.sh /data/adb/service.d/99-gpm-helper.sh
chmod 755 /data/adb/service.d/99-gpm-helper.sh
echo "installed:"
ls -l /data/adb/gpm/gpminput /data/adb/service.d/99-gpm-helper.sh
# start it now (the boot script would do this on the next boot)
pkill -f "gpm/gpminput" 2>/dev/null || true
mkdir -p /data/data/$PKG/files
nohup /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 &
sleep 1.5
ls -l /data/data/$PKG/files/gpm.sock 2>&1
