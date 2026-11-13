#!/system/bin/sh
# press X and D-pad up almost together (chord: x+up = volume up)
/data/local/tmp/vgpad key 307 3000 6000 &
sleep 0.2
/data/local/tmp/vgpad hat 0 -1 300 6100 &
wait
