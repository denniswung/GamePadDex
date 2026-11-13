#!/system/bin/sh
PKG=com.dennis.gamepadmouse
echo "== dex/window shell commands =="
cmd -l 2>/dev/null | grep -iE 'dex|window|display' | head -8
echo "== current task =="
dumpsys activity activities 2>/dev/null | grep -oE 'Task\{[^}]*#21[0-9][^}]*piliplus[^}]*\}' | head -2
TID=$(dumpsys activity activities 2>/dev/null | grep -oE '#2[0-9]{2} type=standard A=10337:com.example.piliplus' | grep -oE '#2[0-9]{2}' | tr -d '#' | head -1)
echo "tid=$TID"
echo "== bounds before =="
dumpsys activity activities 2>/dev/null | grep -m2 'bounds=\[[0-9]*,[0-9]*\]\[2' | head -2
if [ -n "$TID" ]; then
  echo "== am task resize $TID 0 0 2560 1600 =="
  am task resize $TID 0 0 2560 1600 2>&1 | head -3
  sleep 3
  echo "== bounds after =="
  dumpsys activity activities 2>/dev/null | grep -m3 'bounds=\[' | head -3
fi
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 3
F=$(ls -t /data/data/$PKG/files/snap_*.png | head -1); cp "$F" /data/local/tmp/rsz.png; chmod 666 /data/local/tmp/rsz.png
echo "shot=$(stat -c%s /data/local/tmp/rsz.png)"
