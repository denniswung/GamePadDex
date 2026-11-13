#!/system/bin/sh
# hold both sticks toward bottom-right for 4 s (two virtual pads, helper grabs both)
/data/local/tmp/vgpad stick 0 30000 4000 2600 >/dev/null 2>&1 &
/data/local/tmp/vgpad stick 1 30000 4000 2600 >/dev/null 2>&1 &
wait
echo done
