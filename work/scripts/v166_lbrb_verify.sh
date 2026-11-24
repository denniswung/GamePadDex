#!/system/bin/sh
# v1.66 t23: LB/RB 机制互斥 + 连续性 + 速度 + 回归（真机，客观证据）
#   用法：sh /data/local/tmp/v166_lbrb_verify.sh
#   输出：/data/local/tmp/v166_lbrb.log + 原始切片 /data/local/tmp/lbrb_raw/
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v166_lbrb.log
RAW=/data/local/tmp/lbrb_raw
mkdir -p "$RAW"
: > "$OUT"
PASS=0; FAIL=0; FAILED=""
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ # $1 id $2 阈值/描述 $3 实测 $4 PASS|FAIL [$5 repro]
  if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
  L "[$1] $4 | 阈值: $2 | 实测: $3"
  [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"
}
now_ms(){ awk '{printf "%d", $1*1000}' /proc/uptime 2>/dev/null; }
prefs(){ cat $(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1) 2>/dev/null; }
vt(){ prefs | grep -o 'v_touch_scroll" value="[a-z]*"' | sed 's/.*value="//;s/"//'; }
set_vt(){ # $1 true|false
  am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref v_touch_scroll --ez bval "$1" >/dev/null 2>&1
  sleep 1.2
}
picked(){ # $1=Z|V -> "count totalpx"
  local s n tot=0 a b c d
  s=$(grep -a "^SWIPE .* axis=$1 " "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/')
  n=0
  while read -r a b c d; do
    [ -z "$a" ] && continue
    n=$((n+1))
    dx=$((c>a?c-a:a-c)); dy=$((d>b?d-b:b-d))
    if [ "$dy" -gt "$dx" ]; then tot=$((tot+dy)); else tot=$((tot+dx)); fi
  done <<EOF
$s
EOF
  echo "$n $tot"
}
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
dump_ui(){
  local i=0
  while [ $i -lt 3 ]; do
    i=$((i+1))
    rm -f /sdcard/lbrb.xml /sdcard/lbrb.lines 2>/dev/null
    timeout 12 uiautomator dump /sdcard/lbrb.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/lbrb.xml > /sdcard/lbrb.lines 2>/dev/null
    grep -q '第 [1-5] 页\|列表项 #' /sdcard/lbrb.lines 2>/dev/null && return 0
    sleep 0.6
  done
  return 1
}
PY=0; HS=0
scroll_metrics(){
  PY=-1; HS=0
  local n l b x1 y1 x2 y2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/lbrb.lines 2>/dev/null)
    [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')
    [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2-x1))
    if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
}
list_top(){ # "index y"  取可见列表项里 y 最小者
  grep -ao 'text="列表项 #[0-9]*"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' /sdcard/lbrb.lines 2>/dev/null \
   | sed -E 's/.*text="列表项 #([0-9]+)".*bounds="\[[0-9]*,([0-9]+)\].*/\1 \2/' \
   | awk '{ if ($2!="" && ($2<best || best=="")) { best=$2; idx=$1 } } END{ print (idx==""?"-1 0":idx" "best) }'
}
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.1; }
hold_lb(){ $VG key 310 $1 400 >/dev/null 2>&1; }   # LB 按住 $1 ms
hold_rb(){ $VG key 311 $1 400 >/dev/null 2>&1; }
focus(){ dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*u0 //;s/}.*//'; }
hashes(){
  L "  apk=$(sha256sum "$(pm path $PKG | sed 's/package://')" | awk '{print $1}')"
  L "  helper=$(sha256sum /data/adb/gpm/gpminput | awk '{print $1}')"
  L "  module=$(sha256sum /data/adb/modules/gpm_dex/gpminput | awk '{print $1}')"
  L "  version=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//')/$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')"
  L "  screen=$(dumpsys window displays | sed -n 's/.*cur=\([0-9]*x[0-9]*\).*/\1/p' | head -1) wf=$(dumpsys power | grep -m1 mWakefulness | sed 's/.*=//') rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
  L "  vtouch=$(vt) prefs=[$(prefs | tr -d '\n' | sed 's/<map>//;s/<\/map>//' | sed 's/  */ /g' | cut -c1-260)]"
}
# ---------------------------------------------------------------- A 互斥
sec "A 机制互斥：LB / RB 各按住 1.5s（触屏模式）"
set_vt true
starts
l3
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.0      # 页面下滚，给 LB 留出可滚空间
for btn in LB RB; do
  : > "$HL"
  logcat -c
  sleep 0.2
  if [ "$btn" = "LB" ]; then hold_lb 1500; else hold_rb 1500; fi
  sleep 1.0
  local_sw=$(swipe_n); local_wh=$(wheel_n)
  cp "$HL" "$RAW/A_${btn}_helper.log" 2>/dev/null
  grep -a '^SWIPE \|^WHEEL' "$HL" > "$RAW/A_${btn}_slice.txt" 2>/dev/null
  mode=$(logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | tail -1 | sed 's/^.*DexPad *: //')
  axz=$(grep -ac '^SWIPE .* axis=Z ' "$HL" 2>/dev/null); axv=$(grep -ac '^SWIPE .* axis=V ' "$HL" 2>/dev/null)
  L "  $btn: SWIPE=$local_sw (Z=$axz V=$axv) WHEEL=$local_wh mode=[$mode]"
  if [ "$local_sw" -gt 0 ] && [ "$local_wh" -eq 0 ]; then
    ck "A-$btn" "一次按压内 SWIPE>0 且 WHEEL=0（同按只一种机制，触屏=连续滑动）" "SWIPE=$local_sw WHEEL=$local_wh mode=[$mode]" PASS
  else
    ck "A-$btn" "一次按压内 SWIPE>0 且 WHEEL=0（同按只一种机制，触屏=连续滑动）" "SWIPE=$local_sw WHEEL=$local_wh mode=[$mode]" FAIL "grep -a '^SWIPE \|^WHEEL' $HL; logcat -d -s DexPad | grep hold-scroll"
  fi
  logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll\|wheel stopped' > "$RAW/A_${btn}_engine.txt" 2>/dev/null
done

# ---------------------------------------------------------------- B 触屏连续性
sec "B 触屏模式：内容连续位移 + 相邻位移间隔"
starts
l3
logcat -c
: > "$HL"
dump_ui; scroll_metrics; PY0=$PY
hold_lb 1500
sleep 1.2
dump_ui; scroll_metrics; PY1=$PY
dpy=$((PY0 - PY1)); [ "$dpy" -lt 0 ] && dpy=$((-dpy))
lbsw=$(swipe_n)
L "  LB 1.5s: PY $PY0->$PY1 d=$dpy SWIPE=$lbsw"
if [ "$dpy" -ge 1000 ] && [ "$lbsw" -ge 6 ]; then
  ck B-LB "LB 1.5s 竖向内容位移 dPY ≥1000px（helper 连续 SWIPE ≥6 条）" "dPY=$dpy SWIPE=$lbsw" PASS
else
  ck B-LB "LB 1.5s 竖向内容位移 dPY ≥1000px（helper 连续 SWIPE ≥6 条）" "dPY=$dpy SWIPE=$lbsw" FAIL "starts; hold LB 1.5s; uiautomator dump（PY）"
fi
# RB：向上滚（先下滚 400ms 让页面留出 ≥1000px 的上滚空间；页面贴底时 padtest 的下部子视图会吃掉拖拽）
starts
l3
$VG stick 4 24000 350 >/dev/null 2>&1; sleep 0.9
dump_ui; scroll_metrics
local_wi=0
while [ "$PY" -gt 450 ] && [ $local_wi -lt 6 ]; do
  $VG stick 4 24000 100 >/dev/null 2>&1; sleep 0.7
  dump_ui; scroll_metrics
  local_wi=$((local_wi+1))
done
while [ "$PY" -lt 250 ] && [ "$PY" -ge 0 ] && [ $local_wi -lt 10 ]; do
  $VG stick 4 -24000 100 >/dev/null 2>&1; sleep 0.7
  dump_ui; scroll_metrics
  local_wi=$((local_wi+1))
done
L "  RB 前置：下滚至 PY=$PY（微调 $local_wi 次，目标 ≤450 且 ≥250）"
logcat -c
: > "$HL"
dump_ui; scroll_metrics; PY2=$PY; HS2=$HS
hold_rb 1500
sleep 1.2
dump_ui; scroll_metrics; PY3=$PY; HS3=$HS
dpy2=$((PY3 - PY2)); [ "$dpy2" -lt 0 ] && dpy2=$((-dpy2))
dhs2=$((HS3 - HS2)); [ "$dhs2" -lt 0 ] && dhs2=$((-dhs2))
rbsw=$(swipe_n)
L "  RB 1.5s: PY $PY2->$PY3 d=$dpy2 HS $HS2->$HS3 d=$dhs2 SWIPE=$rbsw"
if { [ "$dpy2" -ge 1000 ] || [ "$dhs2" -ge 400 ]; } && [ "$rbsw" -ge 6 ]; then
  ck B-RB "RB 1.5s 内容位移（竖 dPY≥1000 或横 dHS≥400，SWIPE≥6）" "dPY=$dpy2 dHS=$dhs2 SWIPE=$rbsw" PASS
else
  ck B-RB "RB 1.5s 内容位移（竖 dPY≥1000 或横 dHS≥400，SWIPE≥6）" "dPY=$dpy2 dHS=$dhs2 SWIPE=$rbsw" FAIL "starts; hold RB 1.5s; uiautomator dump"
fi
# 间隔：每次手势的 click-down 时间戳（PadProbe），start-to-start - 220ms = 空档
cds=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'MOUSE/click-down' | sed -n -E 's/^([0-9-]+) ([0-9:.]+).*/\2/p')
gaps=""; prev=""; maxgap=0; ncd=0
for t in $cds; do
  ncd=$((ncd+1))
  if [ -n "$prev" ]; then
    d=$(awk -v a="$prev" -v b="$t" 'BEGIN{ split(a,x,":"); split(b,y,":"); ta=x[1]*3600+x[2]*60+x[3]; tb=y[1]*3600+y[2]*60+y[3]; printf "%.0f", (tb-ta)*1000-220 }')
    gaps="$gaps $d"; [ "$d" -gt "$maxgap" ] && maxgap=$d
  fi
  prev=$t
done
L "  gesture click-down n=$ncd gaps(ms,扣除220ms手势时长)=[$gaps] max=$maxgap"
echo "n=$ncd gaps=[$gaps] max=$maxgap" > "$RAW/B_intervals.txt"
if [ "$ncd" -ge 6 ] && [ "$maxgap" -le 150 ]; then
  ck B-INT "相邻位移空档 ≤150ms（无 >150ms 空档；按每次注入手势的 click-down 时间戳扣除 220ms 手势时长）" "n=$ncd maxgap=${maxgap}ms gaps=[$gaps]" PASS
else
  ck B-INT "相邻位移空档 ≤150ms（无 >150ms 空档）" "n=$ncd maxgap=${maxgap}ms gaps=[$gaps]" FAIL "logcat -d -s PadProbe | grep MOUSE/click-down"
fi

# ---------------------------------------------------------------- C 滚轮模式
sec "C 滚轮模式（v_touch_scroll=false；系统设置列表）"
set_vt false
L "  vtouch=$(vt)"
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3.0
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2    # L3 让指针可见并居中在设置列表上
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "P 1280 700 2560 1600" >/dev/null 2>&1
sleep 0.4
am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "P 1280 800 2560 1600" >/dev/null 2>&1
sleep 0.5
$VG key 304 60 500 >/dev/null 2>&1; sleep 0.8
dump_txt(){ # "text y" 列表
  timeout 12 uiautomator dump /sdcard/lbrb_set.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/lbrb_set.xml > /sdcard/lbrb_set.lines 2>/dev/null
  grep -ao 'text="[^"]\{1,40\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' /sdcard/lbrb_set.lines 2>/dev/null \
    | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1|\2/' | head -40
}
dump_txt > "$RAW/C_set_before.txt"
: > "$HL"; logcat -c
hold_lb 1500
sleep 1.2
dump_txt > "$RAW/C_set_after.txt"
wh=$(wheel_n); sw=$(swipe_n)
mode=$(logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | tail -1 | sed 's/^.*DexPad *: //')
# 同一文本节点的 y 位移（取所有共同文本的最大 |Δy|）
dset=$(awk -F'|' 'NR==FNR{ b[$1]=$2; next } { if ($1 in b && b[$1]!="" && $2!="") { d=b[$1]-$2; if(d<0)d=-d; if(d>m) m=d } } END{ print (m==""?0:m) }' "$RAW/C_set_before.txt" "$RAW/C_set_after.txt")
L "  LB 1.5s: WHEEL=$wh SWIPE=$sw 设置列表共同文本最大位移 dSET=${dset}px mode=[$mode]"
if [ "$wh" -ge 8 ] && [ "$sw" -eq 0 ]; then
  ck C-WHEEL "滚轮模式按住 LB 1.5s：WHEEL 步数 ≥8 且 SWIPE=0" "WHEEL=$wh SWIPE=$sw mode=[$mode]" PASS
else
  ck C-WHEEL "滚轮模式按住 LB 1.5s：WHEEL 步数 ≥8 且 SWIPE=0" "WHEEL=$wh SWIPE=$sw mode=[$mode]" FAIL "set_vt false; hold LB; grep '^WHEEL' $HL"
fi
if [ "${dset:-0}" -ge 100 ]; then
  ck C-MOVE "滚轮模式内容连续位移（系统设置列表同一文本节点 uiautomator 前后差 ≥100px）" "dSET=${dset}px（WHEEL=$wh SWIPE=0）" PASS
else
  ck C-MOVE "滚轮模式内容连续位移（系统设置列表同一文本节点 uiautomator 前后差 ≥100px）" "dSET=${dset}px before=[$(head -3 "$RAW/C_set_before.txt" | tr '\n' ';')] after=[$(head -3 "$RAW/C_set_after.txt" | tr '\n' ';')]" FAIL "wheel 是否到达设置列表：cat $RAW/C_set_before.txt $RAW/C_set_after.txt"
fi
cmd statusbar collapse >/dev/null 2>&1

# ---------------------------------------------------------------- D 稳定性（30s 内多次按压）
sec "D 按压期间机制不切换（30s 内多次按压）"
starts
l3
sw=0; wh=0; bad=0; presses=0
t_start=$(now_ms)
set_vt true
while [ $(( $(now_ms) - t_start )) -lt 15000 ]; do
  : > "$HL"; logcat -c
  if [ $((presses % 2)) -eq 0 ]; then hold_lb 900; else hold_rb 900; fi
  presses=$((presses + 1))
  sleep 0.4
  s=$(swipe_n); w=$(wheel_n)
  [ "$s" -gt 0 ] && [ "$w" -eq 0 ] && sw=$((sw+1)) || bad=$((bad+1))
  m=$(logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | tail -1 | grep -o 'mode=[a-z]*')
  L "  touch press#$presses SWIPE=$s WHEEL=$w $m"
done
t_start=$(now_ms)
set_vt false
wp=0; wbad=0; wpresses=0
while [ $(( $(now_ms) - t_start )) -lt 15000 ]; do
  : > "$HL"; logcat -c
  if [ $((wpresses % 2)) -eq 0 ]; then hold_lb 900; else hold_rb 900; fi
  wpresses=$((wpresses + 1))
  sleep 0.4
  s=$(swipe_n); w=$(wheel_n)
  [ "$w" -gt 0 ] && [ "$s" -eq 0 ] && wp=$((wp+1)) || wbad=$((wbad+1))
  m=$(logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | tail -1 | grep -o 'mode=[a-z]*')
  L "  wheel press#$wpresses SWIPE=$s WHEEL=$w $m"
done
L "  touch: ok=$sw bad=$bad (n=$presses) ; wheel: ok=$wp bad=$wbad (n=$wpresses)"
if [ "$bad" -eq 0 ] && [ "$wbad" -eq 0 ] && [ "$sw" -ge 3 ] && [ "$wp" -ge 3 ]; then
  ck D-STABLE "30s 内多次按压机制不切换（触屏全 swipe、滚轮全 wheel；切换次数=0）" "touch ok=$sw/$presses wheel ok=$wp/$wpresses bad=0" PASS
else
  ck D-STABLE "30s 内多次按压机制不切换（触屏全 swipe、滚轮全 wheel；切换次数=0）" "touch ok=$sw/$presses bad=$bad ; wheel ok=$wp/$wpresses bad=$wbad" FAIL "反复 hold LB/RB 并统计 SWIPE/WHEEL"
fi

# ---------------------------------------------------------------- E 速度
sec "E 速度（竖 1.5s 总位移）"
set_vt true
starts
l3
: > "$HL"; logcat -c
hold_lb 1500
sleep 1.0
set -- $(picked Z); zn=$1; zs=$2
L "  滑动模式 LB 1.5s: Z=$zn total=${zs}px"
if [ "$zn" -ge 6 ] && [ "${zs:-0}" -ge 3360 ]; then
  ck E-SPEED "滑动模式竖 1.5s 总位移 ≥3360px（v1.66 基线）" "n=$zn total=${zs}px（单条≈$((zs/zn))px）" PASS
else
  ck E-SPEED "滑动模式竖 1.5s 总位移 ≥3360px（v1.66 基线）" "n=$zn total=${zs}px" FAIL "hold LB 1.5s; grep '^SWIPE ' $HL"
fi
set_vt false
starts
l3
: > "$HL"; logcat -c
hold_lb 1500
sleep 1.0
whn=$(wheel_n)
L "  滚轮模式 LB 1.5s: WHEEL=$whn（等效 ≥8 步/1.5s）"
if [ "$whn" -ge 8 ]; then
  ck E-WHEEL "滚轮模式 1.5s 等效步数 ≥8（v1.66 等效）" "WHEEL=$whn steps/1.5s" PASS
else
  ck E-WHEEL "滚轮模式 1.5s 等效步数 ≥8（v1.66 等效）" "WHEEL=$whn steps/1.5s" FAIL "set_vt false; hold LB 1.5s; grep '^WHEEL' $HL"
fi

# ---------------------------------------------------------------- F 回归
sec "F 回归"
set_vt true
# F1 X+LB 上一页：横向手势 dx>0
starts
: > "$HL"; logcat -c
$VG combo 307 310 300 2600 >/dev/null 2>&1
sleep 1.2
s=$(grep -a '^SWIPE ' "$HL" | head -1)
x1=$(echo "$s" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$s" | awk '{print $5}' | cut -d, -f1)
dx=0; [ -n "$x1" ] && [ -n "$x2" ] && dx=$((x2-x1))
L "  X+LB: $s"
if [ -n "$s" ] && [ "$dx" -gt 0 ]; then ck F1 "X+LB 上一页：横向手势 dx>0" "dx=+$dx" PASS
else ck F1 "X+LB 上一页：横向手势 dx>0" "dx=$dx s=[$s]" FAIL "vgpad combo 307 310 300 2600"; fi
# F2 X+RB 下一页 dx<0
: > "$HL"; logcat -c
$VG combo 307 311 300 2600 >/dev/null 2>&1
sleep 1.2
s=$(grep -a '^SWIPE ' "$HL" | head -1)
x1=$(echo "$s" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$s" | awk '{print $5}' | cut -d, -f1)
dx=0; [ -n "$x1" ] && [ -n "$x2" ] && dx=$((x2-x1))
L "  X+RB: $s"
if [ -n "$s" ] && [ "$dx" -lt 0 ]; then ck F2 "X+RB 下一页：横向手势 dx<0" "dx=$dx" PASS
else ck F2 "X+RB 下一页：横向手势 dx<0" "dx=$dx s=[$s]" FAIL "vgpad combo 307 311 300 2600"; fi
# F3 右摇杆竖滚
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 >/dev/null 2>&1
sleep 1.0
set -- $(picked Z); zn=$1; zs=$2
vn=$(grep -ac '^SWIPE .* axis=V ' "$HL"); whn=$(wheel_n)
if [ "$zn" -ge 4 ] && [ "$vn" -eq 0 ] && [ "$whn" -eq 0 ]; then ck F3 "右摇杆竖滚：Z≥4 且无 V/wheel" "Z=$zn V=$vn wheel=$whn" PASS
else ck F3 "右摇杆竖滚：Z≥4 且无 V/wheel" "Z=$zn V=$vn wheel=$whn" FAIL "vgpad stick 4 -24000 1500"; fi
# F4 右摇杆横滚
: > "$HL"; logcat -c
$VG stick 3 24000 1500 >/dev/null 2>&1
sleep 1.0
zv=$(grep -ac '^SWIPE .* axis=Z ' "$HL"); vv=$(grep -ac '^SWIPE .* axis=V ' "$HL"); whn=$(wheel_n)
if [ "$vv" -ge 1 ] && [ "$zv" -eq 0 ] && [ "$whn" -eq 0 ]; then ck F4 "右摇杆横滚：V≥1 且无 Z/wheel" "V=$vv Z=$zv wheel=$whn" PASS
else ck F4 "右摇杆横滚：V≥1 且无 Z/wheel" "V=$vv Z=$zv wheel=$whn" FAIL "vgpad stick 3 24000 1500"; fi
# F5 d-pad + DPAD_CENTER（A 注入）
starts
logcat -c
$VG hat 0 1 600 >/dev/null 2>&1
sleep 0.8
$VG key 304 80 600 >/dev/null 2>&1
sleep 0.8
mc=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down')
ke=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER')
if [ "$ke" -ge 1 ] && [ "$mc" -eq 0 ]; then ck F5 "d-pad 粘性导航 + A 注入 DPAD_CENTER" "mouse_click=$mc key_enter=$ke" PASS
else ck F5 "d-pad 粘性导航 + A 注入 DPAD_CENTER" "mouse_click=$mc key_enter=$ke" FAIL "vgpad hat 0 1 600; key 304"; fi
# F6 X 双击 -> Recents
$VG double 307 60 200 2600 >/dev/null 2>&1
sleep 2.0
top=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*u0 //;s/}.*//')
case "$top" in *Recents*|*quickstep*) R=1 ;; *) R=0 ;; esac
if [ "$R" = "1" ]; then ck F6 "X 双击 400ms → 多任务 Recents" "top=$top" PASS
else ck F6 "X 双击 400ms → 多任务 Recents" "top=$top" FAIL "vgpad double 307 60 200 2600"; fi
# F7 空闲隐藏恢复 0px
starts
l3
$VG key 304 60 700 >/dev/null 2>&1      # 使指针可见并点一下
sleep 1.2
P1=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'MOUSE/click-down' | tail -1 | sed -n -E 's/.*x=([0-9]+) y=([0-9]+).*/\1 \2/p')
sleep 9.5
logcat -c
$VG key 304 60 700 >/dev/null 2>&1
sleep 1.2
P2=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'MOUSE/click-down' | tail -1 | sed -n -E 's/.*x=([0-9]+) y=([0-9]+).*/\1 \2/p')
corr=$(logcat -d -s DexPad 2>/dev/null | grep -am1 'no correction move')
d=$(awk -v a="$P1" -v b="$P2" 'BEGIN{ split(a,p," "); split(b,q," "); if(p[1]==""||q[1]==""){print 999; exit} dx=p[1]-q[1]; dy=p[2]-q[2]; if(dx<0)dx=-dx; if(dy<0)dy=-dy; print (dx>dy)?dx:dy }')
if [ "$d" -le 10 ] && [ -n "$P1" ] && [ -n "$P2" ] && [ -n "$corr" ]; then ck F7 "空闲隐藏原地恢复 0px + 无修正移动" "P1=[$P1] P2=[$P2] d=${d}px corr=[$corr]" PASS
else ck F7 "空闲隐藏原地恢复 0px + 无修正移动" "P1=[$P1] P2=[$P2] d=${d}px" FAIL "click; sleep 9.5; click"; fi
# F8 SELECT 通知栏（截图面积变化）
starts
screencap -p /sdcard/lbrb_before.png 2>/dev/null
$VG key 314 100 900 >/dev/null 2>&1
sleep 1.8
screencap -p /sdcard/lbrb_after.png 2>/dev/null
shade=$(dumpsys window 2>/dev/null | grep -c 'NotificationShade')
if [ "$shade" -ge 1 ]; then ck F8 "SELECT 通知栏展开（NotificationShade + 截图前后差异）" "shade=$shade before=$(stat -c %s /sdcard/lbrb_before.png 2>/dev/null)B after=$(stat -c %s /sdcard/lbrb_after.png 2>/dev/null)B" PASS
else ck F8 "SELECT 通知栏展开（NotificationShade + 截图前后差异）" "shade=$shade" FAIL "vgpad key 314 100 900; dumpsys window | grep NotificationShade"; fi
cp /sdcard/lbrb_before.png /sdcard/lbrb_after.png "$RAW/" 2>/dev/null

# ---------------------------------------------------------------- G 环境
sec "G 设备/应用/助手哈希"
hashes
L "  focus=$(focus)"

# ---------------------------------------------------------------- 恢复
sec "RESTORE"
set_vt true
cmd statusbar collapse >/dev/null 2>&1
starts >/dev/null 2>&1
L "  vtouch=$(vt) focus=$(focus) helper=$(pidof gpminput) engine=$(pidof $PKG) vg=$(pidof vgpad)"
L "  恢复: screen=$(dumpsys window displays | sed -n 's/.*cur=\([0-9]*x[0-9]*\).*/\1/p' | head -1) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) wf=$(dumpsys power | grep -m1 mWakefulness | sed 's/.*=//')"
L ""
L "PASS=$PASS FAIL=$FAIL"
[ -n "$FAILED" ] && L "FAILED_IDS:$FAILED"
echo "RESULT: $OUT ; RAW: $RAW"
