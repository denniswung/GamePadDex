#!/system/bin/sh
# deploy + start the root scroll injector daemon, then smoke test
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/inject.sock
DEX=/data/adb/gpm/inject.dex
chmod 644 $DEX
pkill -f "ScrollInject" 2>/dev/null
sleep 0.6
rm -f $SOCK
mkdir -p /data/data/$PKG/files
setsid app_process -Djava.class.path=$DEX /system/bin ScrollInject $SOCK \
    >/data/local/tmp/inject.log 2>&1 </dev/null &
sleep 2.5
echo "== injector state =="
ls -l $SOCK 2>&1
tail -3 /data/local/tmp/inject.log
ps -A | grep -c ScrollInject

echo "== smoke test: inject 5 steps at (1280,800) display 9 =="
{
  for i in 1 2 3 4 5; do echo "1280 800 3 0 9"; sleep 0.1; done
} | app_process -Djava.class.path=$DEX /system/bin ScrollInject /data/local/tmp/tmp.sock 2>/dev/null &
sleep 0.3
kill %1 2>/dev/null
echo done
