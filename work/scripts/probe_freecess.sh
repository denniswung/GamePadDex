#!/system/bin/sh
echo "== packages =="
pm list packages 2>/dev/null | grep -i -E 'freecess|sdhms|sm_core|sm$|devicecare|powerkeeper' | head -20
echo "== settings global/system/secure with free/sleep =="
for ns in global system secure; do
  echo "-- $ns"
  settings list $ns 2>/dev/null | grep -i -E 'freecess|sleep|freeze' | head -20
done
echo "== dumpsys -l | grep free =="
dumpsys -l 2>/dev/null | grep -i -E 'free|sleep' | head
