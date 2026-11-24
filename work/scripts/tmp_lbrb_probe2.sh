#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/p.xml; L=/sdcard/p.lines; PY=0
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
py(){ PY=-1; local n l b; for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" $L 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
ltop(){ grep -ao 'text="列表项 #[0-9]*"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*#([0-9]+)".*\[[0-9]*,([0-9]+)\].*/\1 \2/' | awk '{if($2!=""&&($2<best||best=="")){best=$2;idx=$1}} END{print (idx==""?"-1 0":idx" "best)}'; }
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
dump; py; echo "fresh: PY=$PY list=$(ltop)"
echo "layout y=400..1200:"; grep -ao 'text="[^"]\{1,22\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\].*/\1  y=\2..\3/' | awk -F'y=' '{split($2,a,"."); if(a[1]+0>=300 && a[1]+0<=1250) print}' | head -10
: > /data/adb/gpm/helper.log
$VG stick 4 24000 900 >/dev/null 2>&1; sleep 1.2
dump; py; echo "after stick-down 900ms: PY=$PY list=$(ltop)"
$VG key 310 1500 400 >/dev/null 2>&1; sleep 1.2
dump; py; echo "after LB: PY=$PY list=$(ltop)"
grep -a '^SWIPE ' /data/adb/gpm/helper.log | tail -2
