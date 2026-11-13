#!/system/bin/sh
PKG=com.dennis.gamepadmouse
state() {
  echo "== state $1 =="
  dumpsys activity activities 2>/dev/null | grep -A2 '#243 type=standard' | grep -E 'bounds=|immersive|mode=' | head -3
  am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
  sleep 2.5
  F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1)
  cp "$F" /data/local/tmp/$1.png
  chmod 666 /data/local/tmp/$1.png
  echo "$1=$(stat -c%s /data/local/tmp/$1.png)"
}
state s1
logcat -c
echo "== tap (touch) the fullscreen button =="
input -d 8 tap 2445 30
sleep 3
logcat -d 2>/dev/null | grep -E 'Immersive|onEnterOrExit' | tail -5
state s2
echo "== tap again (toggle back) =="
logcat -c
input -d 8 tap 2445 30
sleep 3
logcat -d 2>/dev/null | grep -E 'Immersive|onEnterOrExit' | tail -5
state s3
