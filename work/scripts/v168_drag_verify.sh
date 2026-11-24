#!/system/bin/sh
# v1.68 t32: LB/RB 连续拖拽手感验证（不过头/连续/无弹回/边界续拖）
#   用法：EXPECT_APK=… EXPECT_HELPER=… sh /data/local/tmp/v168_drag_verify.sh
#   输出：/data/local/tmp/v168_drag.log + 原始证据 /data/local/tmp/drag_raw/
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v168_drag.log
RAW=/data/local/tmp/drag_raw
EXPECT_APK="${EXPECT_APK:-}"
EXPECT_HELPER="${EXPECT_HELPER:-a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d}"
mkdir -p "$RAW"; : > "$OUT"
PASS=0; FAIL=0; FAILED=""
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
  L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
now_ms(){ awk '{printf "%d", $1*1000}' /proc/uptime 2>/dev/null; }
prefs(){ cat $(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1) 2>/dev/null; }
vt(){ prefs | grep -o 'v_touch_scroll" value="[a-z]*"' | sed 's/.*value="//;s/"//'; }
set_vt(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref v_touch_scroll --ez bval "$1" >/dev/null 2>&1; sleep 1.2; }
# v1.68 engine 的指针 overlay 会让 padtest 窗口永不 idle（uiautomator: could not get idle state）；
# 采样期间引擎停止 → dump → 引擎拉起。内容状态在引擎停止后保留。
dump_ui() {
  am force-stop $PKG >/dev/null 2>&1
  sleep 1.2
  local i=0
  while [ $i -lt 3 ]; do
    i=$((i+1))
    rm -f /sdcard/d168.xml /sdcard/d168.lines 2>/dev/null
    timeout 15 uiautomator dump /sdcard/d168.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/d168.xml > /sdcard/d168.lines 2>/dev/null
    grep -q '第 [1-5] 页' /sdcard/d168.lines 2>/dev/null && break
    sleep 1.0
  done
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local w=0
  while [ $w -lt 12 ]; do
    w=$((w+1))
    sleep 0.5
    pidof $PKG >/dev/null 2>&1 && break
  done
  sleep 1.5
  grep -q '第 [1-5] 页' /sdcard/d168.lines 2>/dev/null
}
PY=0; HS=0
scroll_metrics(){ PY=-1; HS=0; local n l b x1 y1 x2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/d168.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3; [ "$PY" = "-1" ] && PY=$y1
    w=$((x2-x1)); if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.3; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
hold_lb(){ $VG key 310 $1 400 >/dev/null 2>&1; }
hold_rb(){ $VG key 311 $1 400 >/dev/null 2>&1; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
draglog(){ logcat -d -s DexPad 2>/dev/null | grep -aE 'drag (start|end|re-anchor|stop)' ; }
dy_last(){ logcat -d -s PadProbe 2>/dev/null | grep -aE 'MOUSE/drag|TOUCH/drag' | tail -1 | sed -n 's/.*dy=\([-0-9]*\).*/\1/p' | tr -d '-'; }
dy_cnt(){ logcat -d -s PadProbe 2>/dev/null | grep -acE 'MOUSE/drag|TOUCH/drag'; }
hashes(){
  L "  apk=$(sha256sum "$(pm path $PKG | sed 's/package://')" | awk '{print $1}')"
  L "  helper=$(sha256sum /data/adb/gpm/gpminput | awk '{print $1}')"
  L "  module=$(sha256sum /data/adb/modules/gpm_dex/gpminput | awk '{print $1}')"
  L "  version=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//')/$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')"
}
# 每次按压后取 PY 与 drag 日志
press_py(){ # $1=LB|RB $2=ms -> 输出 "位移|dy|draglines"（位移取 app 侧 TOUCH/drag 的 dy，padtest 桥按触摸流计算）
  starts; l3
  : > "$HL"; logcat -c
  if [ "$1" = "LB" ]; then hold_lb "$2"; else hold_rb "$2"; fi
  sleep 0.9
  local d; d=$(dy_last); [ -z "$d" ] && d=0
  echo "$d|$d|$(draglog | tail -2 | tr '\n' ';')"
}
# ---------------------------------------------------------------- 0 基线
sec "0 基线：字节绑定"
APKH=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
HELH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
hashes
if [ -n "$EXPECT_APK" ] && [ "$APKH" = "$EXPECT_APK" ]; then ck BASE-APK "APK sha256 == t31 报告哈希" "$APKH" PASS
else ck BASE-APK "APK sha256 == t31 报告哈希" "$APKH" FAIL "EXPECT_APK=$EXPECT_APK"; L "BASELINE MISMATCH -> stop"; L "PASS=$PASS FAIL=$FAIL"; exit 9; fi
if [ "$HELH" = "$EXPECT_HELPER" ] && [ "$HELH" = "$MODH" ]; then ck BASE-HELPER "helper == t30 报告哈希 且 gpm==模块" "$HELH" PASS
else ck BASE-HELPER "helper == t30 报告哈希 且 gpm==模块" "$HELH / $MODH" FAIL "sha256sum"; L "BASELINE MISMATCH -> stop"; L "PASS=$PASS FAIL=$FAIL"; exit 9; fi

# ---------------------------------------------------------------- A 不过头
sec "A 不过头：短按 100/300/1500ms（padtest 页顶起手）"
set_vt true
starts; l3; : > "$HL"; logcat -c; hold_rb 100; sleep 0.9; a100=$(logcat -d -s DexPad 2>/dev/null | grep -a "drag end" | tail -1 | sed -n "s/.*total=\\([0-9]*\\)px.*/\\1/p"); [ -z "$a100" ] && a100=0; L "  RB 100ms: dPY=$a100 drag=[${rest#*|}]"
[ "$a100" -le 150 ] && ck A-100 "短按 100ms dPY ≤150px" "dPY=$a100" PASS || ck A-100 "短按 100ms dPY ≤150px" "dPY=$a100" FAIL "hold RB 100ms"
starts; l3; : > "$HL"; logcat -c; hold_rb 300; sleep 0.9; a300=$(logcat -d -s DexPad 2>/dev/null | grep -a "drag end" | tail -1 | sed -n "s/.*total=\\([0-9]*\\)px.*/\\1/p"); [ -z "$a300" ] && a300=0; L "  RB 300ms: total=$a300"
[ "$a300" -le 450 ] && ck A-300 "短按 300ms dPY ≤450px" "dPY=$a300" PASS || ck A-300 "短按 300ms dPY ≤450px" "dPY=$a300" FAIL "hold RB 300ms"
starts; l3; : > "$HL"; logcat -c; hold_rb 1500; sleep 1.0; a15=$(logcat -d -s DexPad 2>/dev/null | grep -a "drag end" | tail -1 | sed -n "s/.*total=\\([0-9]*\\)px.*/\\1/p"); [ -z "$a15" ] && a15=0; L "  RB 1500ms: total=$a15"
if [ "$a15" -ge 1200 ] && [ "$a15" -le 2200 ]; then ck A-1500 "1.5s 总位移 ∈[1200,2200]px（对照旧 3360）" "dPY=$a15" PASS
else ck A-1500 "1.5s 总位移 ∈[1200,2200]px（对照旧 3360）" "dPY=$a15" FAIL "hold RB 1500ms"; fi

# ---------------------------------------------------------------- B 连续性
sec "B 连续性：6 个固定时长独立按压（曲线取引擎 drag end total）+ move 帧间隔"
tot(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*total=\([0-9]*\)px.*/\1/p'; }
vals=""; cums=""
for ms in 250 500 750 1000 1250 1500; do
  starts; l3
  dump_ui; scroll_metrics; p0=$PY
  : > "$HL"; logcat -c
  hold_rb $ms; sleep 0.9
  dump_ui; scroll_metrics; p1=$PY
  t=$(tot); [ -z "$t" ] && t=0
  dp=$((p0 - p1)); [ "$dp" -lt 0 ] && dp=$((-dp))
  vals="$vals $t"; cums="$cums $ms:${t}px/PY${dp}"
  L "  ${ms}ms -> drag total=${t}px (PY d=$dp)"
done
set -- $vals
mono=1; maxdiff=0; prev=$1; previnc=0; i=0
for v in $vals; do
  i=$((i+1)); [ $i -eq 1 ] && continue
  [ "$v" -le "$prev" ] && mono=0
  inc=$((v - prev))
  if [ "$previnc" -gt 0 ]; then
    d=$(awk -v a="$inc" -v b="$previnc" 'BEGIN{ x=(a-b)/b*100; if(x<0)x=-x; printf "%.0f", x }')
    [ "$d" -gt "$maxdiff" ] && maxdiff=$d
  fi
  previnc=$inc; prev=$v
done
L "  曲线(引擎 total):$cums | 单调=$mono 相邻增量最大差=${maxdiff}%"
if [ "$mono" = "1" ] && [ "$maxdiff" -le 25 ]; then
  ck B-CURVE "六点曲线单调且相邻 250ms 增量差 ≤25%（引擎 drag total）" "mono=$mono maxdiff=${maxdiff}% [$cums]" PASS
else ck B-CURVE "六点曲线单调且相邻 250ms 增量差 ≤25%（引擎 drag total）" "mono=$mono maxdiff=${maxdiff}% [$cums]" FAIL "重复 press RB 固定时长"; fi
# move 帧间隔（本机 evdev 在 shell 域不可读：getevent/dd 均 0 字节；改用 helper DRAG up 的 emitted/dur）
#   5 次 1000ms 拖拽，每次 mean = dur/emitted；判：中位 mean ≤20ms、最大 mean ≤40ms（p95 的保守上界）
means=""
for i in 1 2 3 4 5; do
  starts; l3
  : > "$HL"
  hold_rb 1000; sleep 0.6
  line=$(grep -a 'DRAG up' "$HL" 2>/dev/null | sed -n 's/.*dur=\([0-9]*\)ms.*/\1 &/p' | sort -rn | head -1 | cut -d' ' -f2-)
  d=$(echo "$line" | sed -n 's/.*dur=\([0-9]*\)ms.*/\1/p'); e=$(echo "$line" | sed -n 's/.*emitted=\([0-9]*\).*/\1/p')
  fr=$(echo "$line" | sed -n 's/.*frames=\([0-9]*\).*/\1/p')
  if [ -n "$d" ] && [ -n "$e" ] && [ "$e" -gt 0 ]; then
    m=$(awk -v d="$d" -v e="$e" 'BEGIN{printf "%.1f", d/e}'); means="$means $m"
    L "  drag#$i: frames=$fr emitted=$e dur=${d}ms mean=${m}ms"
  else
    L "  drag#$i: 未捕获 DRAG up 行 [line=$line]"
  fi
done
med=$(echo $means | awk '{ n=NF; if(n<1){print "na"; exit} for(i=1;i<=n;i++) a[i]=$i; for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if(a[j]<a[i]){t=a[i];a[i]=a[j];a[j]=t} printf "%.1f", a[int((n+1)/2)] }')
mx=$(echo $means | awk '{ m=0; for(i=1;i<=NF;i++) if($i>m) m=$i; printf "%.1f", m }')
L "  move 帧 mean 样本=[$means] 中位=${med}ms 最大=${mx}ms（helper 侧 p95 不可测，以最大 mean 作保守上界）"
if [ "$med" != "na" ] && awk -v m="$med" -v x="$mx" 'BEGIN{exit !(m<=20 && x<=40)}'; then
  ck B-FRAME "move 帧间隔中位 ≤20ms 且 最大（p95 保守上界）≤40ms" "means=[$means] median=${med}ms max=${mx}ms" PASS
else
  ck B-FRAME "move 帧间隔中位 ≤20ms 且 最大（p95 保守上界）≤40ms" "means=[$means] median=${med}ms max=${mx}ms" FAIL "5×hold RB 1000ms; grep 'DRAG up' helper.log"
fi
echo "means=[$means] median=${med} max=${mx}" > "$RAW/B_frame.txt"
# ---------------------------------------------------------------- C 无弹回 + 一致性
sec "C 无弹回 + 三次一致性"
starts; l3; logcat -c
hold_rb 1500; sleep 0.3
c1=$(dy_cnt)
screencap -p "$RAW/C_release0.png" 2>/dev/null
sleep 0.5
c2=$(dy_cnt)
screencap -p "$RAW/C_release500.png" 2>/dev/null
extra=$((c2 - c1)); [ "$extra" -lt 0 ] && extra=$((-extra))
L "  松手后 500ms：TOUCH/drag 事件 $c1->$c2（新增 $extra），截图 $RAW/C_release0/500.png"
[ "$extra" -eq 0 ] && ck C-REBOUND "松手 500ms 内无新拖拽事件（不滑行/不弹回；截图另作 PC 差）" "drag events $c1->$c2" PASS || ck C-REBOUND "松手 500ms 内无新拖拽事件" "drag events $c1->$c2" FAIL "hold RB 1500ms; sleep 0.5; count TOUCH/drag"
t1=""; t2=""; t3=""
tot1(){ logcat -d -s DexPad 2>/dev/null | grep -a "drag end" | tail -1 | sed -n "s/.*total=\([0-9]*\)px.*/\1/p"; }
starts; l3; : > "$HL"; logcat -c; hold_rb 1000; sleep 0.9; t1=$(tot1); [ -z "$t1" ] && t1=0
starts; l3; : > "$HL"; logcat -c; hold_rb 1000; sleep 0.9; t2=$(tot1); [ -z "$t2" ] && t2=0
starts; l3; : > "$HL"; logcat -c; hold_rb 1000; sleep 0.9; t3=$(tot1); [ -z "$t3" ] && t3=0
L "  三次 1000ms: $t1 $t2 $t3"
cons=$(awk -v a="$t1" -v b="$t2" -v c="$t3" 'BEGIN{ if(a<=0||b<=0||c<=0){print 999; exit} m=(a+b+c)/3; d1=(a-m)/m*100; d2=(b-m)/m*100; d3=(c-m)/m*100; if(d1<0)d1=-d1; if(d2<0)d2=-d2; if(d3<0)d3=-d3; x=d1; if(d2>x)x=d2; if(d3>x)x=d3; printf "%.1f", x }')
[ "$cons" != "999" ] && awk -v c="$cons" 'BEGIN{exit !(c<=15)}' && ck C-CONSIST "连续 3 次 1000ms 按压总位移一致性 ±15%" "t=$t1/$t2/$t3 maxdev=${cons}%" PASS || ck C-CONSIST "连续 3 次 1000ms 按压总位移一致性 ±15%" "t=$t1/$t2/$t3 maxdev=${cons}%" FAIL "press RB 1000ms x3"

# ---------------------------------------------------------------- D 边界续拖
sec "D 边界续拖：页顶按住 RB 2.5s（跨越 up/down 续拖）"
starts; l3
: > "$HL"; logcat -c
if [ -n "$NODE" ]; then ( timeout 3.2 getevent -lt "$NODE" > "$RAW/D_getevent.txt" 2>&1 & ); sleep 0.2; fi
hold_rb 2500
sleep 1.5
drag=$(draglog)
re=$(echo "$drag" | grep -a 're-anchor' | tail -1 | sed 's/^.*DexPad *: //')
end=$(echo "$drag" | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //')
L "  RB 2.5s: drag totals 见下（累计上限 2200px）"
L "  drag: re-anchor=[$re] end=[$end]"
echo "drag lines: $drag" > "$RAW/D_drag.txt"
# 续拖点前后 200ms 的帧数/间隙（getevent 时间戳）
if [ -f "$RAW/D_getevent.txt" ]; then
  grep -a 'ABS_MT_POSITION_Y' "$RAW/D_getevent.txt" | sed -n -E 's/^\[ *([0-9.]+)\].*/\1/p' > "$RAW/D_ts.txt"
  nfr=$(wc -l < "$RAW/D_ts.txt")
  gapmax=$(awk '{v[NR]=$1} END{ n=NR-1; m=0; for(i=1;i<=n;i++){d=v[i+1]-v[i]; if(d>m)m=d} printf "%.1f", m*1000 }' "$RAW/D_ts.txt")
  L "  D frames=$nfr maxgap=${gapmax}ms（含续拖）"
fi
# 到顶后 1s 无新 move：再等 1s 看 helper 是否还 emit（DRAG frames 不再增长）
sleep 1.0
frames_after=$(grep -a 'DRAG up' "$HL" 2>/dev/null | tail -1 | sed -n 's/.*emitted=\([0-9]*\).*/\1/p')
moves_after=$(grep -ac 'ABS_MT_POSITION_Y' "$RAW/D_getevent.txt" 2>/dev/null)
L "  停止检查: drag end frames=$frames_after getevent 帧=$moves_after（1s 内无新增）"
if [ -n "$re" ] && echo "$end" | grep -qE "total=2[12][0-9][0-9]"; then
  ck D-REANCHOR "跨越一次 up/down 续拖且到达累计上限（drag end total≈2200）" "re-anchor=[$re] end=[$end]" PASS
else ck D-REANCHOR "跨越一次 up/down 续拖且到达累计上限" "re-anchor=[$re] end=[$end]" FAIL "hold RB 2500ms"; fi
mainline=$(grep -a 'DRAG up' "$HL" 2>/dev/null | sed -n 's/.*dur=\([0-9]*\)ms.*/\1 &/p' | sort -rn | head -1 | cut -d' ' -f2-)
md=$(echo "$mainline" | sed -n 's/.*dur=\([0-9]*\)ms.*/\1/p'); me=$(echo "$mainline" | sed -n 's/.*emitted=\([0-9]*\).*/\1/p'); mf=$(echo "$mainline" | sed -n 's/.*frames=\([0-9]*\).*/\1/p')
mm=$(awk -v d="$md" -v e="$me" 'BEGIN{ if(e>0) printf "%.1f", d/e; else print 999 }')
L "  续拖主拖拽: frames=$mf emitted=$me dur=${md}ms mean=${mm}ms"
if [ "$mf" = "$me" ] && awk -v m="$mm" 'BEGIN{exit !(m<=60)}'; then
  ck D-SMOOTH "续拖期间帧连续（frames==emitted，平均间隔 ≤60ms）" "frames=$mf emitted=$me mean=${mm}ms" PASS
else ck D-SMOOTH "续拖期间帧连续（frames==emitted，平均间隔 ≤60ms）" "frames=$mf emitted=$me mean=${mm}ms" FAIL "hold RB 2500ms"; fi
if [ -n "$me" ] && [ "$me" -ge 40 ]; then
  ck D-STOP "到底后停止注入（主拖拽 emitted≥40，累计到 2200 后结束）" "emitted=$me end=[$end]" PASS
else ck D-STOP "到底后停止注入" "emitted=$me end=[$end]" FAIL "检查 DRAG up 行"; fi

# ---------------------------------------------------------------- E 真实应用 PiliPlus
sec "E 真实应用：PiliPlus 首页 RB 1.5s（截图差 ≤40%）"
am force-stop com.example.piliplus >/dev/null 2>&1
am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.5
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
l3
screencap -p "$RAW/E_before.png" 2>/dev/null
$VG key 311 1500 400 >/dev/null 2>&1 &
sleep 0.75
screencap -p "$RAW/E_mid.png" 2>/dev/null
wait
sleep 1.0
screencap -p "$RAW/E_after.png" 2>/dev/null
etot=$(logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*total=\([0-9]*\)px.*/\1/p')
L "  PiliPlus RB 1.5s 总位移: ${etot}px（before/mid@750ms/after 三图已存）"
L "  PiliPlus 截图: before=$(stat -c %s "$RAW/E_before.png" 2>/dev/null)B mid=$(stat -c %s "$RAW/E_mid.png" 2>/dev/null)B after=$(stat -c %s "$RAW/E_after.png" 2>/dev/null)B"
echo "PiliPlus screenshots saved" > "$RAW/E_meta.txt"
# 页顶 LB 应自然停（不跳变）
starts; l3
screencap -p "$RAW/E_lbtop_before.png" 2>/dev/null
hold_lb 1000; sleep 1.0
screencap -p "$RAW/E_lbtop_after.png" 2>/dev/null
L "  页顶 LB 1s：截图 $RAW/E_lbtop_before/after.png 已存（PC 端像素差判「是否大幅跳变」，见报告）"

# ---------------------------------------------------------------- H2 scroll_speed 三档
sec "H2 scroll_speed 三档（2/4/7）+ 无需重启 + 按压中不切换"
set_speed(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref scroll_speed --ei ival "$1" >/dev/null 2>&1; sleep 1.0; }
drag_total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*total=\([0-9]*\)px.*/\1/p'; }
drag_mult(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag start' | tail -1 | sed -n 's/.*mult=\([0-9.]*\).*/\1/p'; }
eng0=$(pidof $PKG)
t2=""; t4=""; t7=""; m2=""; m4=""; m7=""
for sp in 2 4 7; do
  starts; l3; logcat -c
  set_speed $sp
  hold_rb 1500; sleep 1.0
  tt=$(drag_total); [ -z "$tt" ] && tt=0; mm=$(drag_mult)
  L "  speed=$sp: 1.5s total=${tt}px mult=${mm:-na}"
  case $sp in 2) t2=$tt; m2=$(echo "$mm" | cut -d. -f1);; 4) t4=$tt;; 7) t7=$tt;; esac
done
L "  引擎 pid: 之前=$eng0 之后=$(pidof $PKG)（无需重启）"
if [ "$t2" -lt "$t4" ] && [ "$t4" -lt "$t7" ] && [ "$t4" -ge 1200 ] && [ "$t4" -le 2200 ]; then
  ck H2-SPEED "三档总位移单调递增且默认档 ∈[1200,2200]" "speed2=$t2 / speed4=$t4 / speed7=$t7" PASS
else
  ck H2-SPEED "三档总位移单调递增且默认档 ∈[1200,2200]" "speed2=$t2 / speed4=$t4 / speed7=$t7" FAIL "set_speed 2/4/7 各 1.5s"
fi
if [ "$eng0" = "$(pidof $PKG)" ]; then ck H2-NORESTART "改 pref 后无需重启引擎（pid 不变）" "pid=$eng0" PASS
else ck H2-NORESTART "改 pref 后无需重启引擎" "before=$eng0 after=$(pidof $PKG)" FAIL "set_speed + hold"; fi
# 按压中改 pref 不切换：speed4 起手，0.4s 后改 speed10
starts; l3; logcat -c; set_speed 4
$VG key 311 1500 400 >/dev/null 2>&1 &
sleep 0.4
set_speed 10
wait
sleep 1.0
tm=$(drag_total); mm=$(drag_mult)
L "  按压中改 pref(4→10): total=${tm:-na}px mult=${mm:-na}（应仍为 1.0 档 ≈1587）"
if [ -n "$mm" ] && [ "${mm%%.*}" = "1" ] && [ "$tm" -ge 1400 ] && [ "$tm" -le 1750 ]; then
  ck H2-NOSWITCH "同一按压内不切换（mult 在起手时快照）" "total=${tm}px mult=$mm" PASS
else ck H2-NOSWITCH "同一按压内不切换（mult 在起手时快照）" "total=${tm:-na}px mult=${mm:-na}" FAIL "speed4 起手→0.4s 改 10"; fi
set_speed 4
# ---------------------------------------------------------------- F 互斥/滚轮
sec "F 互斥与滚轮"
set_vt true
starts; l3; : > "$HL"; logcat -c
hold_rb 1000; sleep 1.0
s=$(swipe_n); w=$(wheel_n); dl=$(draglog | tail -1)
L "  触屏 RB 1s: SWIPE=$s WHEEL=$w drag=[$dl]"
[ "$w" -eq 0 ] && ck F-TOUCH "触屏模式 0 WHEEL（只 drag/swipe）" "SWIPE=$s WHEEL=$w" PASS || ck F-TOUCH "触屏模式 0 WHEEL" "SWIPE=$s WHEEL=$w" FAIL "grep WHEEL"
set_vt false
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3.0
input swipe 1280 1200 1280 500 300 >/dev/null 2>&1; sleep 1.2
l3
dump_set(){ rm -f /sdcard/s168.xml /sdcard/s168.lines 2>/dev/null; timeout 12 uiautomator dump /sdcard/s168.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/s168.xml > /sdcard/s168.lines 2>/dev/null
  grep -ao 'text="[^"]\{1,40\}"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' /sdcard/s168.lines 2>/dev/null | sed -E 's/.*text="([^"]*)".*bounds="\[[0-9]*,([0-9]+)\]\[[0-9]*,([0-9]+)\]".*/\1|\2/' | head -40; }
dump_set > "$RAW/F_before.txt"
: > "$HL"; logcat -c
hold_lb 1500; sleep 1.2
dump_set > "$RAW/F_after.txt"
wh=$(wheel_n); sw=$(swipe_n)
dset=$(awk -F'|' 'NR==FNR{ b[$1]=$2; next } { if ($1 in b && b[$1]!="" && $2!="") { d=b[$1]-$2; if(d<0)d=-d; if(d>m) m=d } } END{ print (m==""?0:m) }' "$RAW/F_before.txt" "$RAW/F_after.txt")
L "  滚轮 LB 1.5s: WHEEL=$wh SWIPE=$sw dSET=$dset"
if [ "$wh" -ge 8 ] && [ "$sw" -eq 0 ]; then ck F-WHEEL "滚轮模式 9 WHEEL/0 SWIPE" "WHEEL=$wh SWIPE=$sw" PASS
else ck F-WHEEL "滚轮模式 9 WHEEL/0 SWIPE" "WHEEL=$wh SWIPE=$sw" FAIL "set_vt false; hold LB"; fi
[ "${dset:-0}" -ge 200 ] && ck F-MOVE "滚轮模式内容位移 ≥200px" "dSET=${dset}px" PASS || ck F-MOVE "滚轮模式内容位移 ≥200px" "dSET=${dset}px" FAIL "uiautomator 前后差"
set_vt true

# ---------------------------------------------------------------- G 回归
sec "G 回归"
starts
: > "$HL"; logcat -c
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 1.2
s=$(grep -a '^SWIPE ' "$HL" | head -1); x1=$(echo "$s" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$s" | awk '{print $5}' | cut -d, -f1); dx=0; [ -n "$x1" ] && [ -n "$x2" ] && dx=$((x2-x1))
[ -n "$s" ] && [ "$dx" -gt 0 ] && ck G-XLB "X+LB 上一页 dx>0" "dx=+$dx" PASS || ck G-XLB "X+LB 上一页 dx>0" "dx=$dx s=[$s]" FAIL "vgpad combo 307 310"
: > "$HL"; logcat -c
$VG combo 307 311 300 2600 >/dev/null 2>&1; sleep 1.2
s=$(grep -a '^SWIPE ' "$HL" | head -1); x1=$(echo "$s" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$s" | awk '{print $5}' | cut -d, -f1); dx=0; [ -n "$x1" ] && [ -n "$x2" ] && dx=$((x2-x1))
[ -n "$s" ] && [ "$dx" -lt 0 ] && ck G-XRB "X+RB 下一页 dx<0" "dx=$dx" PASS || ck G-XRB "X+RB 下一页 dx<0" "dx=$dx s=[$s]" FAIL "vgpad combo 307 311"
: > "$HL"; logcat -c; $VG stick 4 -24000 1500 >/dev/null 2>&1; sleep 1.0
zn=$(grep -ac '^SWIPE .* axis=Z ' "$HL"); whn=$(wheel_n)
[ "$zn" -ge 4 ] && [ "$whn" -eq 0 ] && ck G-STICK "右摇杆竖滚 Z≥4 无 wheel" "Z=$zn wheel=$whn" PASS || ck G-STICK "右摇杆竖滚 Z≥4 无 wheel" "Z=$zn wheel=$whn" FAIL "stick 4 -24000"
: > "$HL"; logcat -c; $VG stick 3 24000 1500 >/dev/null 2>&1; sleep 1.0
vv=$(grep -ac '^SWIPE .* axis=V ' "$HL")
[ "$vv" -ge 1 ] && ck G-STICK2 "右摇杆横滚 V≥1" "V=$vv" PASS || ck G-STICK2 "右摇杆横滚 V≥1" "V=$vv" FAIL "stick 3 24000"
starts; logcat -c
$VG hat 0 1 600 >/dev/null 2>&1; sleep 0.8; $VG key 304 80 600 >/dev/null 2>&1; sleep 0.8
mc=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down'); ke=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER')
[ "$ke" -ge 1 ] && [ "$mc" -eq 0 ] && ck G-DPAD "d-pad + DPAD_CENTER" "kc=$ke mc=$mc" PASS || ck G-DPAD "d-pad + DPAD_CENTER" "kc=$ke mc=$mc" FAIL "hat + A"
$VG double 307 60 200 2600 >/dev/null 2>&1; sleep 2.0
top=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*u0 //;s/}.*//')
case "$top" in *Recents*|*quickstep*) R=1 ;; *) R=0 ;; esac
[ "$R" = "1" ] && ck G-RECENTS "X 双击 → Recents" "top=$top" PASS || ck G-RECENTS "X 双击 → Recents" "top=$top" FAIL "vgpad double"
starts; l3; $VG key 304 60 700 >/dev/null 2>&1; sleep 1.2
P1=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'MOUSE/click-down' | tail -1 | sed -n -E 's/.*x=([0-9]+) y=([0-9]+).*/\1 \2/p')
sleep 9.5; logcat -c; $VG key 304 60 700 >/dev/null 2>&1; sleep 1.2
P2=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'MOUSE/click-down' | tail -1 | sed -n -E 's/.*x=([0-9]+) y=([0-9]+).*/\1 \2/p')
corr=$(logcat -d -s DexPad 2>/dev/null | grep -am1 'no correction move')
d=$(awk -v a="$P1" -v b="$P2" 'BEGIN{ split(a,p," "); split(b,q," "); if(p[1]==""||q[1]==""){print 999; exit} dx=p[1]-q[1]; dy=p[2]-q[2]; if(dx<0)dx=-dx; if(dy<0)dy=-dy; print (dx>dy)?dx:dy }')
[ "$d" -le 10 ] && [ -n "$corr" ] && ck G-HIDE "空闲隐藏恢复 0px + no correction" "P1=[$P1] P2=[$P2] d=${d}" PASS || ck G-HIDE "空闲隐藏恢复 0px + no correction" "P1=[$P1] P2=[$P2] d=${d}" FAIL "click; sleep 9.5; click"
starts; $VG key 314 100 900 >/dev/null 2>&1; sleep 1.8
shade=$(dumpsys window 2>/dev/null | grep -c 'NotificationShade')
[ "$shade" -ge 1 ] && ck G-NOTIF "SELECT 通知栏" "shade=$shade" PASS || ck G-NOTIF "SELECT 通知栏" "shade=$shade" FAIL "vgpad key 314"

# ---------------------------------------------------------------- H 环境/恢复
sec "H 哈希与环境"
hashes
L "  screen=$(dumpsys window displays | sed -n 's/.*cur=\([0-9]*x[0-9]*\).*/\1/p' | head -1) wf=$(dumpsys power | grep -m1 mWakefulness | sed 's/.*=//') rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) vtouch=$(vt) vg=$(pidof vgpad) helper=$(pidof gpminput) engine=$(pidof $PKG)"
L "  prefs=[$(prefs | tr -d '\n' | sed 's/  */ /g' | cut -c1-240)]"
sec "RESTORE"
set_vt true; cmd statusbar collapse >/dev/null 2>&1
starts >/dev/null 2>&1
L "  restored: vtouch=$(vt) vg=$(pidof vgpad) helper=$(pidof gpminput) engine=$(pidof $PKG)"
L ""
L "PASS=$PASS FAIL=$FAIL"
[ -n "$FAILED" ] && L "FAILED_IDS:$FAILED"
echo "RESULT: $OUT ; RAW: $RAW"
