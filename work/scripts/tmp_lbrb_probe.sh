#!/system/bin/sh
VG=/data/local/tmp/vgpad
D=/sdcard/p.xml
L=/sdcard/p.lines
PY=0
dump(){ timeout 12 uiautomator dump $D >/dev/null 2>&1; sed 's/></>\n</g' $D > $L 2>/dev/null; }
py(){ PY=-1; local n l b y; for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" $L 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
ltop(){ grep -ao 'text="列表项 #[0-9]*"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*#([0-9]+)".*\[[0-9]*,([0-9]+)\].*/\1 \2/' | awk '{if($2!=""&&($2<best||best=="")){best=$2;idx=$1}} END{print (idx==""?"-1 0":idx" "best)}'; }
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.0
cmd statusbar collapse >/dev/null 2>&1; sleep 0.3
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.1
$VG stick 4 -24000 1500 >/dev/null 2>&1; sleep 1.0
dump; py; echo "top state: PY=$PY list=$(ltop)"
echo "nodes near y=1500:"; grep -ao 'text="[^"]\{1,24\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' $L 2>/dev/null | sed -E 's/.*text="([^"]*)".*\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\].*/\1 y=\2..\3/' | head -12
# P 放置指针到 (1280,1500)
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "P 1280 1500 2560 1600" >/dev/null 2>&1
sleep 0.8
dump; py; echo "after P: PY=$PY list=$(ltop)"
$VG key 310 1500 400 >/dev/null 2>&1; sleep 1.2
dump; py; echo "after LB: PY=$PY list=$(ltop)"
grep -a '^SWIPE ' /data/adb/gpm/helper.log | tail -3
