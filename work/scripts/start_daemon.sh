#!/system/bin/sh
PKG=com.dennis.gamepadmouse
BIN=/data/adb/gpm/gpminput
SOCK=/data/data/$PKG/files/gpm.sock
chmod 755 /data/local/tmp/gpminput /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $BIN
chmod 755 $BIN
pkill -f "gpm/gpminput" 2>/dev/null
pkill -f "test.sock" 2>/dev/null
sleep 0.6
rm -f $SOCK
mkdir -p /data/data/$PKG/files
setsid $BIN --socket $SOCK >/data/local/tmp/gpm-daemon.log 2>&1 < /dev/null &
sleep 1.5
echo "== daemon process =="
ps -A -o PID,ARGS | grep gpminput | grep -v grep
echo "== socket =="
ls -l $SOCK 2>&1
echo "== daemon log =="
cat /data/local/tmp/gpm-daemon.log 2>&1 | head -3
