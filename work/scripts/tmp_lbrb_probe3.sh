#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/p.xml; L=/sdcard/p.lines; PY=0
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
py(){ PY=-1; local n l b; for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" $L 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
echo "--- to bottom ---"
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.2; dump; py; echo "PY=$PY"
echo "--- stick up 900ms ---"
$VG stick 4 -24000 900 >/dev/null 2>&1; sleep 1.2; dump; py; echo "PY=$PY"
echo "--- RB press 1500ms (after reset to bottom) ---"
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.2; dump; py; echo "PY_before=$PY"
: > /data/adb/gpm/helper.log
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.3; dump; py; echo "PY_after=$PY"
grep -a '^SWIPE ' /data/adb/gpm/helper.log | tail -3
