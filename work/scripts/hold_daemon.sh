#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
pkill -f "gpm/gpminput" 2>/dev/null
sleep 0.5
rm -f $SOCK
mkdir -p /data/data/$PKG/files
/data/adb/gpm/gpminput --socket $SOCK >/data/local/tmp/gpm-daemon.log 2>&1 < /dev/null &
DPID=$!
echo "daemon pid $DPID"
sleep 900