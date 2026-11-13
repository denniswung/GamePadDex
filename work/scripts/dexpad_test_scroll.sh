#!/system/bin/sh
# measure wheel steps produced for a given right-stick deflection
# usage: dexpad_test_scroll.sh <absAxis> <rawValue> <normLabel>
DEV=/dev/input/event19
AX=$1
V=$2
N=$3
OUT=/data/local/tmp/sc_${AX}_${V}.txt
# vgpad holds the stick for 1.2 s starting 6.0 s after launch; capture only
# the pressing window, otherwise the event capture misses it entirely
/data/local/tmp/vgpad stick $AX $V 1200 6000 >/dev/null 2>&1 &
sleep 5.8
timeout 2 getevent -lt $DEV > $OUT 2>&1
wait
echo "axis=$AX norm=$N wheels=$(grep -c 'REL_WHEEL' $OUT) hwheels=$(grep -c 'REL_HWHEEL' $OUT)"
