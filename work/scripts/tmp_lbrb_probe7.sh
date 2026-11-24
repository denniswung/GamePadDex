VG=/data/local/tmp/vgpad
D=/sdcard/p.xml; L=/sdcard/p.lines; PY=0
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
py(){ PY=-1; local n l b; for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" $L 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
dump; py; echo "fresh PY=$PY"
$VG stick 4 24000 250 >/dev/null 2>&1; sleep 1.0; dump; py; echo "after down250 PY=$PY"
$VG stick 4 -24000 700 >/dev/null 2>&1; sleep 1.0; dump; py; echo "after up700 PY=$PY"