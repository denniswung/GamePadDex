#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
  cp "$F" /data/local/tmp/$1
  chmod 666 /data/local/tmp/$1
  echo "$1=$(stat -c%s /data/local/tmp/$1)"
}
click() {
  echo "m 8 $1 30 1" | app_process -Djava.class.path=$DEX /system/bin ScrollInject --stdio 2>/dev/null | tail -1
  sleep 1.5
}
# make sure the app is maximized on the DeX display
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
am task resize 243 0 0 2560 1600 >/dev/null 2>&1
sleep 2
snap base2.png
for X in 2390 2418 2445 2472; do
  echo "--- click x=$X ---"
  click $X
  snap "x$X.png"
done
