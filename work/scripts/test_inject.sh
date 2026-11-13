#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 644 /data/adb/gpm/inject.dex
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  ls -t /data/data/$PKG/files/snap_*.png | head -1
}
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 1
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
rm -f /data/data/$PKG/files/snap_*.png
A=$(snap); cp "$A" /data/local/tmp/a.png
echo "A=$A"
echo "== inject 5 scroll steps at (1700,600) =="
{
  for i in 1 2 3 4 5; do echo "1700 600 3"; sleep 0.15; done
} | CLASSPATH=/data/adb/gpm/inject.dex app_process /system/bin ScrollInject 2>/data/local/tmp/inject.log
sleep 1
cat /data/local/tmp/inject.log | tail -8
B=$(snap); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
ls -l /data/local/tmp/a.png /data/local/tmp/b.png
