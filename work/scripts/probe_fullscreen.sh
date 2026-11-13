#!/system/bin/sh
PKG=com.dennis.gamepadmouse
DEX=/data/adb/gpm/inject.dex
DISP=8
snap() {
  OUT=$1
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
  cp "$F" /data/local/tmp/$OUT
  chmod 666 /data/local/tmp/$OUT
  echo "$OUT $(stat -c%s /data/local/tmp/$OUT)"
}
combo() {
  echo "--- combo $1 ---"
  echo "c $DISP $1" | app_process -Djava.class.path=$DEX /system/bin ScrollInject --stdio 2>/dev/null
  sleep 1.5
}
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display $DISP >/dev/null 2>&1
sleep 6
snap base.png
combo "meta+up"
snap c1.png
combo "ctrl+shift+enter"
snap c2.png
combo "alt+enter"
snap c3.png
combo "f11"
snap c4.png
combo "meta+shift+enter"
snap c5.png
combo "meta+f"
snap c6.png
