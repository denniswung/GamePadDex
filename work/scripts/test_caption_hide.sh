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
echo "== open Bilibili on the DeX display and maximize it =="
monkey -p com.example.piliplus -c android.intent.category.LAUNCHER 1 --display 8 >/dev/null 2>&1
sleep 6
TID=$(dumpsys activity activities 2>/dev/null | grep -oE 'Task\{[^}]*#2[0-9]{2}[^}]*piliplus' | grep -oE '#2[0-9]{2}' | tr -d '#' | head -1)
echo "task=$TID"
[ -n "$TID" ] && am task resize $TID 0 0 2560 1600 >/dev/null 2>&1
sleep 3
logcat -c
snap fsx.png
echo "== dexfs caption logs =="
logcat -d 2>/dev/null | grep -E '\[dexfs\]' | tail -8
