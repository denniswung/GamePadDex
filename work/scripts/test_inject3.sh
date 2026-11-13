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
echo "A size=$(stat -c%s /data/local/tmp/a.png)"
{
  for i in 1 2 3 4 5 6; do echo "1280 800 3 0 9"; sleep 0.12; done
} | app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin ScrollInject 2>/data/local/tmp/inject.log
sleep 1
tail -3 /data/local/tmp/inject.log
B=$(snap); cp "$B" /data/local/tmp/b.png
chmod 666 /data/local/tmp/a.png /data/local/tmp/b.png
echo "B size=$(stat -c%s /data/local/tmp/b.png)"
