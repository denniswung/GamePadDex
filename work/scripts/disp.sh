#!/system/bin/sh
echo "== displays =="
dumpsys display 2>/dev/null | grep -E '^  Display [0-9]+:|mDisplayId=[0-9]+' | head -10
echo "== power =="
dumpsys power 2>/dev/null | grep -m1 mWakefulness
echo "== unique ids =="
dumpsys display 2>/dev/null | grep -o 'uniqueId="local:[0-9]*"' | sort -u
echo "== desktop mode =="
dumpsys activity activities 2>/dev/null | grep -c 'Display #8'
