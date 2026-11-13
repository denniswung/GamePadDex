#!/system/bin/sh
# push the pointer around with two virtual pads; $1 = axis0 value, $2 = axis1 value, $3 = ms
X=${1:-0}
Y=${2:-0}
MS=${3:-2000}
PRE=2600
if [ "$X" != "0" ]; then
  /data/local/tmp/vgpad stick 0 "$X" "$MS" "$PRE" >/dev/null 2>&1 &
fi
if [ "$Y" != "0" ]; then
  /data/local/tmp/vgpad stick 1 "$Y" "$MS" "$PRE" >/dev/null 2>&1 &
fi
wait
echo "moved x=$X y=$Y for ${MS}ms"
