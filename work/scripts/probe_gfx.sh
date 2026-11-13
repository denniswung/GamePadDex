#!/system/bin/sh
PKG=com.android.settings
am start -n $PKG/.Settings >/dev/null 2>&1
sleep 2
for mode in "view-hierarchy" ""; do
  t0=$(date +%s%N)
  if [ -z "$mode" ]; then
    timeout 10 dumpsys gfxinfo $PKG > /sdcard/g.txt 2>&1
  else
    timeout 10 dumpsys gfxinfo $PKG $mode > /sdcard/g.txt 2>&1
  fi
  t1=$(date +%s%N)
  echo "mode='$mode' ms=$(( (t1-t0)/1000000 )) bytes=$(wc -c < /sdcard/g.txt) lines=$(wc -l < /sdcard/g.txt)"
  grep -ciE 'recyclerview|scrollview|listview' /sdcard/g.txt
done
echo "--- head of view-hierarchy ---"
timeout 10 dumpsys gfxinfo $PKG view-hierarchy 2>/dev/null | head -12
