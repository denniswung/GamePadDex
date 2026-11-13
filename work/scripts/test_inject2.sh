#!/system/bin/sh
PKG=com.dennis.gamepadmouse
chmod 644 /data/adb/gpm/inject.dex
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  ls -t /data/data/$PKG/files/snap_*.png | head -1
}
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 9 >/dev/null 2>&1
sleep 6
rm -f /data/data/$PKG/files/snap_*.png
A=$(snap); cp "$A" /data/local/tmp/a.png
echo "A=$A $(ls -l /data/local/tmp/a.png | awk '{print $5}')"
echo "== inject 6 wheel steps at screen centre =="
{
  echo "1280 800 3"; sleep 0.12
  echo "1280 800 3"; sleep 0.12
  echo "1280 800 3"; sleep 0.12
  echo "1280 800 3"; sleep 0.12
  echo "1280 800 3"; sleep 0.12
  echo "1280 800 3"; sleep 0.12
} | app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin ScrollInject 2>/data/local/tmp/inject.log
sleep 1
tail -4 /data/local/tmp/inject.log
B=$(snap); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B=$B $(ls -l /data/local/tmp/b.png | awk '{print $5}')"
