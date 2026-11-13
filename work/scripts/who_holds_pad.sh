#!/system/bin/sh
echo "== helpers =="
ps -A -o PID,STAT,NAME | grep gpminput | grep -v grep
echo "== who holds the controller node =="
DEV=$(ls /dev/input/event* | while read f; do
  n=$(cat /proc/bus/input/devices 2>/dev/null | grep -B4 "$(basename $f)" | grep -m1 'Name=' | sed 's/Name=//;s/^ *//')
  case "$n" in *Xbox*) echo "$f";; esac
done | head -1)
echo "controller node: $DEV"
for p in $(ls /proc | grep -E '^[0-9]+$'); do
  if ls -l /proc/$p/fd 2>/dev/null | grep -q "$(basename ${DEV:-none})"; then
    echo "held by pid $p: $(cat /proc/$p/cmdline 2>/dev/null | tr '\0' ' ')"
  fi
done
