#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
pkill -f "test.sock" 2>/dev/null
pkill -f "dbg.sock" 2>/dev/null
pkill -f "gpm/gpminput" 2>/dev/null
pkill -f "hold_daemon" 2>/dev/null
sleep 0.6
rm -f $SOCK
mkdir -p /data/data/$PKG/files
setsid /data/adb/gpm/gpminput --socket $SOCK >/data/local/tmp/gpm-daemon.log 2>&1 < /dev/null &
sleep 2
ps -A -o PID,ARGS | grep gpm/gpminput | grep -v grep
ls -l $SOCK