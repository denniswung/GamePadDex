#!/system/bin/sh
BIN=/data/adb/gpm/gpminput
SOCK=/data/local/tmp/dbg.sock
pkill -f dbg.sock 2>/dev/null
sleep 0.5
rm -f $SOCK
setsid $BIN --socket $SOCK >/data/local/tmp/dbg.log 2>&1 < /dev/null &
sleep 2
echo "t+2:"; ps -A -o PID,ARGS | grep dbg.sock | grep -v grep
sleep 10
echo "t+12:"; ps -A -o PID,ARGS | grep dbg.sock | grep -v grep
echo "log:"; cat /data/local/tmp/dbg.log