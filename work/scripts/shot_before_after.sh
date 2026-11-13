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
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 5
snap before_fs.png
echo "== action =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es action dex_fullscreen >/dev/null 2>&1
sleep 3
snap after_fs.png
