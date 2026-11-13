#!/system/bin/sh
PKG=com.dennis.gamepadmouse
snap() {
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
  cp "$F" /data/local/tmp/$1
  chmod 666 /data/local/tmp/$1
  echo "$1=$(stat -c%s /data/local/tmp/$1)"
}
echo "== ensure maximized =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 4
am task resize 243 0 0 2560 1600 >/dev/null 2>&1
sleep 2
snap tap_base.png
echo "== touch tap on the fullscreen icon (2445,30) =="
logcat -c
input -d 8 tap 2445 30 2>&1 | head -2
sleep 2
snap tap_after.png
echo "== window/dex log lines =="
logcat -d 2>/dev/null | grep -iE 'caption|dexwindow|decor|fullscreen|WindowingMode|maximize' | tail -12
