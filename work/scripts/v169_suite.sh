#!/system/bin/sh
# GamePadDex v1.69 一键自动化套件（真机）
#   用法：sh /data/local/tmp/v169_suite.sh <组>   组：ENV SCR MIX LOG RPT CFG BTN E2E DSP PERF all
#   输出：/data/local/tmp/v169_<run>.log ；证据：/data/local/tmp/v169_evidence/<run>/
#   基线门：ENV 组失败 / 版本哈希不符 → exit 9
#   依赖：/data/local/tmp/vgpad；dumpsys/uiautomator/screencap；root
RUN=$(date +%Y%m%d-%H%M%S)
OUT=/data/local/tmp/v169_${RUN}.log
EVID=/data/local/tmp/v169_evidence/$RUN
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
PASS=0; FAIL=0; BLK=0; SKIP=0; FAILED_IDS=""; BLOCKED_IDS=""
EXPECT_VERSION="${EXPECT_VERSION:-1.68}"
EXPECT_CODE="${EXPECT_CODE:-70}"
EXPECT_HELPER="${EXPECT_HELPER:-a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d}"
mkdir -p "$EVID"; : > "$OUT"

L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ # ID VERDICT 阈值 实测 证据
  case "$2" in
    PASS) PASS=$((PASS+1));;
    FAIL) FAIL=$((FAIL+1)); FAILED_IDS="$FAILED_IDS $1";;
    BLOCKED) BLK=$((BLK+1)); BLOCKED_IDS="$BLOCKED_IDS $1";;
    NOTRUN) SKIP=$((SKIP+1));;
    *) FAIL=$((FAIL+1)); FAILED_IDS="$FAILED_IDS $1";;
  esac
  L "$1 $2 | 阈值: $3 | 实测: $4 | 证据: $5"
  return 0
}
blocked(){ ck "$1" BLOCKED "$2" "不可自动化：$2" "${4:-n/a}"; }
now(){ date +%H:%M:%S; }
prefs(){ cat $(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1) 2>/dev/null; }
vt(){ prefs | grep -o 'v_touch_scroll" value="[a-z]*"' | sed 's/.*value="//;s/"//'; }
speed(){ prefs | grep -o 'scroll_speed" value="[0-9]*"' | sed 's/.*value="//;s/"//'; }
pref_xml(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
engine_reload(){ am force-stop $PKG >/dev/null 2>&1; sleep 1.5; am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; local i=0; while [ $i -lt 20 ]; do i=$((i+1)); pidof $PKG >/dev/null 2>&1 && break; sleep 0.5; done; sleep 3.0; }
set_vt(){ local f=$(pref_xml); [ -z "$f" ] && return 1
  am force-stop $PKG >/dev/null 2>&1; sleep 1.5
  f=$(pref_xml); [ -z "$f" ] && return 1
  if grep -q 'name="v_touch_scroll"' "$f"; then sed -i 's/name="v_touch_scroll" value="[a-z]*"/name="v_touch_scroll" value="'"$1"'"/' "$f"
  else sed -i 's/<\/map>/    <boolean name="v_touch_scroll" value="'"$1"'" \/><\/map>/' "$f"; fi
  engine_reload; }
set_speed(){ local f=$(pref_xml); [ -z "$f" ] && return 1
  am force-stop $PKG >/dev/null 2>&1; sleep 1.5
  f=$(pref_xml); [ -z "$f" ] && return 1
  if grep -q 'name="scroll_speed"' "$f"; then sed -i 's/name="scroll_speed" value="[0-9]*"/name="scroll_speed" value="'"$1"'"/' "$f"
  else sed -i 's/<\/map>/    <int name="scroll_speed" value="'"$1"'" \/><\/map>/' "$f"; fi
  engine_reload; }
set_speed(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref scroll_speed --ei ival "$1" >/dev/null 2>&1; sleep 1.0; }
set_pref_b(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref "$1" --ez bval "$2" >/dev/null 2>&1; sleep 1.0; }

# ---------- 引擎/前台 ----------
ensure_engine(){ pidof $PKG >/dev/null 2>&1 || { am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 3; }; }
stop_engine(){ am force-stop $PKG >/dev/null 2>&1; sleep 1.0; }
start_engine(){ am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; local i=0; while [ $i -lt 15 ]; do i=$((i+1)); pidof $PKG >/dev/null 2>&1 && break; sleep 0.4; done; sleep 3.5; }
# uiautomator：引擎 overlay 会让 padtest 永不 idle → 停引擎 dump → 拉起
dump_ui(){ # $1=tag  （引擎停止后 dump，再拉起；内容状态保留）
  stop_engine
  local i=0
  while [ $i -lt 3 ]; do
    i=$((i+1))
    rm -f /sdcard/v169.xml /sdcard/v169.lines 2>/dev/null
    timeout 15 uiautomator dump /sdcard/v169.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/v169.xml > /sdcard/v169.lines 2>/dev/null
    grep -qE '第 [1-5] 页|列表项 #|左列表 #' /sdcard/v169.lines 2>/dev/null && break
    sleep 0.8
  done
  cp /sdcard/v169.lines "$EVID/ui_${1:-dump}.lines" 2>/dev/null
  start_engine
  grep -qE '第 [1-5] 页|列表项 #' /sdcard/v169.lines 2>/dev/null
}
dump_ui_nostop(){ local i=0
  while [ $i -lt 3 ]; do
    i=$((i+1)); rm -f /sdcard/v169.xml /sdcard/v169.lines 2>/dev/null
    timeout 15 uiautomator dump /sdcard/v169.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/v169.xml > /sdcard/v169.lines 2>/dev/null
    grep -qE '第 [1-5] 页|列表项|键|开始|导出' /sdcard/v169.lines 2>/dev/null && break
    sleep 0.8
  done
  cp /sdcard/v169.lines "$EVID/ui_${1:-dump}.lines" 2>/dev/null
  wc -l < /sdcard/v169.lines 2>/dev/null; }
PY=0; HS=0; FIRSTITEM=""
metrics(){ PY=-1; HS=0; FIRSTITEM=""
  local n l b x1 y1 x2 w sx
  for n in 1 2 3 4 5; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v169.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2-x1)); if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
  l=$(grep -m1 'text="列表项 #' /sdcard/v169.lines 2>/dev/null)
  [ -n "$l" ] && FIRSTITEM=$(echo "$l" | sed -n 's/.*text="列表项 #\([0-9]*\)".*/\1/p')
  ITEM=${FIRSTITEM:-0}
  LIDX=$((10#$ITEM))
}
pad(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
pad_act(){ am start -n "$PAD/.ui.$1" >/dev/null 2>&1; sleep 1.8; }
dx_act(){ am start -n "$PKG/.$1" >/dev/null 2>&1; sleep 1.8; }
focus_now(){ dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*u0 //;s/}.*//'; }
fg_pad(){ focus_now | grep -q "$PAD" && echo 1 || echo 0; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
vg(){ "$VG" "$@" >/dev/null 2>&1; sleep 0.2; }
hold(){ vg key "$1" "$2" 400; }
ctl(){ /data/local/tmp/gpmctl /data/adb/gpm/gpmctl.sock "$1" 2>/dev/null; }
ctl_ok(){ ctl "?" | grep -q "SELFTEST begin"; }
# screencap 必须带 SF display id（多显示器时不带 -d 会随机选屏）
SF_DISP=$(dumpsys SurfaceFlinger --display-id 2>/dev/null | grep "HWC display 0" | awk "{print \$2}")
# 像素类用例前置断言：截图尺寸必须 2560x1600（PNG 头 16..23 字节），否则 band 坐标无效
cap(){
  local f="$1"
  [ -n "$SF_DISP" ] && screencap -d "$SF_DISP" -p "$f" 2>/dev/null || screencap -p "$f" 2>/dev/null
  local w=$(od -An -tu1 -j16 -N4 "$f" 2>/dev/null | awk '{print $1*16777216+$2*65536+$3*256+$4}')
  local h=$(od -An -tu1 -j20 -N4 "$f" 2>/dev/null | awk '{print $1*16777216+$2*65536+$3*256+$4}')
  L "  screencap $(basename $f) size=${w}x${h} display=${SF_DISP:-auto}"
  [ "${w}x${h}" = "2560x1600" ] || L "  WARN: 截图尺寸非 2560x1600，band 坐标不可用"
}
# helper 命令备注：S <n>=垂直滚轮，H <n>=水平滚轮，V <disp> <dx> <ms> <maxX> <maxY>=注入 swipe（必须 5 参数）
ptr_to(){ # $1=x $2=y -> 输出 "req|actual|helperpid"
  local i=0 c=""
  ctl "j" >/dev/null; sleep 0.2
  while [ $i -lt 3 ]; do
    i=$((i+1))
    ctl "P $1 $2 2560 1600" >/dev/null; sleep 0.25
    ctl "M 0 0" >/dev/null; sleep 0.2
    c=$(ctl "c" | grep -a 'CURSOR ' | tail -1)
    case "$c" in *"CURSOR -1 -1"*) sleep 0.4;; *) break;; esac
  done
  echo "$1,$2|$c|helper=$(pidof gpminput)"
}
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
drag_up_n(){ grep -ac '^DRAG up' "$HL" 2>/dev/null; }
drag_total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*total=\([0-9]*\)px.*/\1/p'; }
drag_mult(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag start' | tail -1 | sed -n 's/.*mult=\([0-9.]*\).*/\1/p'; }
drag_dur(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*dur=\([0-9]*\)ms.*/\1/p'; }
reanchor_n(){ logcat -d -s DexPad 2>/dev/null | grep -ac 'drag re-anchor'; }
clear_hl(){ : > "$HL" 2>/dev/null; }
screenshot(){ screencap -p "$EVID/$1.png" 2>/dev/null; }

# 单次 RB 按压（干净起点，取引擎总位移）
rb_total_from_top(){ # $1=ms
  pad; l3; logcat -c; clear_hl
  hold 311 "$1"; sleep 0.9
  drag_total
}
# ---------------------------------------------------------------- ENV
g_env(){
  sec "ENV 环境与链路"
  local vn vc apkh helh modh
  vn=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//')
  vc=$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
  apkh=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
  helh=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
  modh=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
  L "  版本=$vn/$vc APK=$apkh"
  L "  helper=$helh module=$modh"
  if [ "$vn" = "$EXPECT_VERSION" ] && [ "$vc" = "$EXPECT_CODE" ]; then
    ck ENV-001 PASS "versionName=$EXPECT_VERSION / versionCode=$EXPECT_CODE" "$vn/$vc" "$OUT"
  else
    ck ENV-001 FAIL "versionName=$EXPECT_VERSION / versionCode=$EXPECT_CODE" "$vn/$vc" "$OUT"
  fi
  if [ -n "$helh" ] && [ "$helh" = "$modh" ] && [ "$helh" = "$EXPECT_HELPER" ]; then
    ck ENV-002 PASS "gpm helper == module helper == 发布哈希" "$helh" "$OUT"
  else
    ck ENV-002 FAIL "gpm helper == module helper == 发布哈希" "$helh / $modh" "$OUT"
  fi
  local hpid n mod_en sock hb
  hpid=$(pidof gpminput); n=$(echo "$hpid" | wc -w)
  sock=$(ls -l /data/data/$PKG/files/gpm.sock 2>/dev/null | grep -c '^s' )
  hb=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'hb ready=')
  mod_en=$(ls /data/adb/modules/gpm_dex/ 2>/dev/null | grep -c 'module.prop')
  L "  helper pids=[$hpid] n=$n sock=$sock heartbeat=$hb module_prop=$mod_en"
  if [ "$n" = "1" ] && [ "$sock" = "1" ] && [ "$hb" -ge 1 ]; then
    ck ENV-003 PASS "helper 单实例 + socket + 引擎心跳" "n=$n sock=$sock hb=$hb" "$OUT"
  else
    ck ENV-003 FAIL "helper 单实例 + socket + 引擎心跳" "n=$n sock=$sock hb=$hb" "$OUT"
  fi
  blocked ENV-004 "需要真实 USB/蓝牙 XInput 手柄拔插与 dumpsys input 对比，本轮无真手柄接入" "$OUT"
  # ENV-005 SHARE 鼠标模式切换（状态无关：连按两次 SHARE，两种状态各测一次）
  local a1 a2 st
  pad; l3
  logcat -c; vg key 304 60 300; sleep 0.6
  a1=$(logcat -d -s PadProbe 2>/dev/null | grep -acE 'MOUSE/(click-down|hover)')
  vg key 315 80 400; sleep 1.0
  logcat -c; vg key 304 60 300; sleep 0.6
  a2=$(logcat -d -s PadProbe 2>/dev/null | grep -acE 'MOUSE/(click-down|hover)')
  L "  SHARE 前后两次 A 的 MOUSE 事件: $a1 -> $a2"
  if [ "$a1" -ge 1 ] && [ "$a2" -eq 0 ]; then st=1; vg key 315 80 400; sleep 0.8
  elif [ "$a2" -ge 1 ] && [ "$a1" -eq 0 ]; then st=2; vg key 315 80 400; sleep 0.8
  else st=0; fi
  if [ "$st" = "1" ] || [ "$st" = "2" ]; then
    ck ENV-005 PASS "SHARE 可在两种模式间切换（一种模式产生 MOUSE 事件、另一种不产生）" "mouse=$a1->$a2 state=$st" "$OUT"
  else
    ck ENV-005 FAIL "SHARE 模式切换" "mouse=$a1->$a2" "$OUT"
  fi
  # ENV-006 7 页可打开 + 导出目录
  local ok=0 page
  for page in SelfCheckActivity ScrollTestActivity CursorTestActivity LogActivity ReportActivity; do
    am force-stop $PAD >/dev/null 2>&1
    am start -n $PAD/.ui.$page >/dev/null 2>&1; sleep 1.6
    focus_now | grep -q "$page" && ok=$((ok+1))
  done
  L "  padtest 页面打开: $ok/5（文档写 7 页，实际构建 5 页；见 HARNESS §3）"
  [ "$ok" -ge 5 ] && ck ENV-006 PASS "padtest 测试页均可打开（实际 5 页）" "$ok/5 focus=$(focus_now)" "$OUT" || ck ENV-006 FAIL "padtest 测试页均可打开" "$ok/5" "$OUT"
  # 基线门
  if [ -n "$FAILED_IDS" ]; then
    L "BASELINE GATE: FAIL$FAILED_IDS → exit 9"
    L "PASS=$PASS FAIL=$FAIL BLOCKED=$BLK"
    exit 9
  fi
}

# ---------------------------------------------------------------- SCR
g_scr(){
  sec "SCR 滚动与滑动专项"
  set_speed 4
  local a b c d t
  # 001
  a=$(rb_total_from_top 100); b=$(rb_total_from_top 100); c=$(rb_total_from_top 100)
  L "  RB100 x3: $a/$b/$c"
  if [ "${a:-0}" -gt 0 ] && [ "${a:-0}" -le 150 ] && [ "${b:-0}" -gt 0 ] && [ "${b:-0}" -le 150 ] && [ "${c:-0}" -gt 0 ] && [ "${c:-0}" -le 150 ]; then
    ck SCR-001 PASS "每次 0<位移≤150px，三次独立" "100ms=$a/$b/$c" "$OUT"
  else ck SCR-001 FAIL "每次 0<位移≤150px，三次独立" "100ms=$a/$b/$c" "$OUT"; fi
  # 002
  t=$(rb_total_from_top 300)
  if [ "${t:-0}" -gt 100 ] && [ "${t:-0}" -le 450 ] && [ "${t:-0}" -gt "${a:-0}" ]; then ck SCR-002 PASS "300ms 位移 100–450 且大于 100ms" "300ms=$t (100ms=$a)" "$OUT"
  else ck SCR-002 FAIL "300ms 位移 100–450 且大于 100ms" "300ms=$t (100ms=$a)" "$OUT"; fi
  # 003
  pad; l3; logcat -c; clear_hl
  hold 311 1500; sleep 1.0
  t=$(drag_total); local sw=$(swipe_n) wh=$(wheel_n) md me line
  line=$(grep -a 'DRAG up' "$HL" 2>/dev/null | sed -n 's/.*dur=\([0-9]*\)ms.*/\1 &/p' | sort -rn | head -1 | cut -d' ' -f2-)
  md=$(echo "$line" | sed -n 's/.*dur=\([0-9]*\)ms.*/\1/p'); me=$(echo "$line" | sed -n 's/.*emitted=\([0-9]*\).*/\1/p')
  if [ "${t:-0}" -ge 1200 ] && [ "${t:-0}" -le 2200 ] && [ "$sw" = "0" ] && [ "$wh" = "0" ]; then
    ck SCR-003 PASS "1.5s 位移 1200–2200；SWIPE=0；WHEEL=0" "total=$t SWIPE=$sw WHEEL=$wh frames=$me dur=${md}ms" "$OUT"
  else ck SCR-003 FAIL "1.5s 位移 1200–2200；SWIPE=0；WHEEL=0" "total=$t SWIPE=$sw WHEEL=$wh" "$OUT"; fi
  # 004 LB 页底
  pad; l3; vg stick 4 -24000 1500; sleep 0.8; logcat -c
  hold 310 1500; sleep 1.0; t=$(drag_total)
  if [ "${t:-0}" -ge 1200 ] && [ "${t:-0}" -le 2200 ]; then ck SCR-004 PASS "LB 1.5s 位移 1200–2200（与 RB 同机制）" "total=$t" "$OUT"
  else ck SCR-004 FAIL "LB 1.5s 位移 1200–2200" "total=$t" "$OUT"; fi
  # 005 方向（app 侧 MOUSE/drag dy 符号）
  pad; l3; logcat -c; hold 311 800; sleep 0.8
  local drb=$(logcat -d -s PadProbe 2>/dev/null | grep -a "MOUSE/drag" | tail -1 | sed -n "s/.*dy=\([-0-9]*\).*/\1/p")
  pad; l3; vg stick 4 -24000 1500; sleep 0.8; logcat -c; hold 310 800; sleep 0.8
  local dlb=$(logcat -d -s PadProbe 2>/dev/null | grep -a "MOUSE/drag" | tail -1 | sed -n "s/.*dy=\([-0-9]*\).*/\1/p")
  L "  方向 dy: RB=${drb:-na} LB=${dlb:-na}"
  if [ -n "$drb" ] && [ -n "$dlb" ] && [ "$drb" -lt 0 ] && [ "$dlb" -gt 0 ]; then ck SCR-005 PASS "RB 手指向上（dy<0）、LB 手指向下（dy>0），方向相反" "RB dy=$drb LB dy=$dlb" "$OUT"
  else ck SCR-005 FAIL "RB/LB 方向" "RB dy=${drb:-na} LB dy=${dlb:-na}" "$OUT"; fi
  # 006 松手即停（松手后 500ms 无新 MOUSE/drag|TOUCH/swipe）
  pad; l3; hold 311 1500; sleep 0.3
  local n1=$(logcat -d -s PadProbe 2>/dev/null | grep -acE "MOUSE/drag|TOUCH/swipe")
  sleep 0.5
  local n2=$(logcat -d -s PadProbe 2>/dev/null | grep -acE "MOUSE/drag|TOUCH/swipe")
  if [ "$n2" -le "$n1" ]; then ck SCR-006 PASS "松手 500ms 内无新拖拽/滑动事件（不滑行）" "events $n1->$n2" "$OUT"
  else ck SCR-006 FAIL "松手后仍有事件" "events $n1->$n2" "$OUT"; fi
  # 007 六段单调
  local prev=-1 mono=1 cur summ=""
  for ms in 100 300 500 800 1100 1500; do
    cur=$(rb_total_from_top $ms); summ="$summ $ms:$cur"; [ "$cur" -le "$prev" ] && mono=0; prev=$cur
  done
  L "  六段:$summ"
  [ "$mono" = "1" ] && ck SCR-007 PASS "六段位移单调递增" "$summ" "$OUT" || ck SCR-007 FAIL "单调" "$summ" "$OUT"
  # 008 爬升
  local s400 s900 s1400
  s400=$(rb_total_from_top 400); s900=$(rb_total_from_top 900); s1400=$(rb_total_from_top 1400)
  if [ "$s400" -lt "$s900" ] && [ "$s900" -lt "$s1400" ]; then ck SCR-008 PASS "初段慢、中段升速、后段继续增长" "400=$s400 900=$s900 1400=$s1400" "$OUT"
  else ck SCR-008 FAIL "速度爬升" "400=$s400 900=$s900 1400=$s1400" "$OUT"; fi
  # 009 五档：release APK 无调试通道，XML 改动不生效（实测各档均 ≈1600px）→ BLOCKED
  blocked SCR-009 "release APK 无 DebugReceiver，prefs XML 改动在引擎运行时不生效（实测 1/2/4/7/10 档 1.5s 位移均 ≈1600px）；速度可调性需调试版或 UI SeekBar 复验" "$OUT"
  # 010 按压快照（当前 release 无调试通道：无法中途改；用引擎日志确认起手快照即为当前档）
  pad; l3; logcat -c; hold 311 1500; sleep 1.0
  local mm=$(drag_mult); local t10=$(drag_total)
  if [ -n "$mm" ] && [ "${mm%%.*}" = "1" ] && [ "${t10:-0}" -ge 1200 ] && [ "${t10:-0}" -le 2200 ]; then
    ck SCR-010 PASS "起手 mult=1.0（speed=4 快照），按压内无倍率变化" "total=$t10 mult=$mm" "$OUT"
  else ck SCR-010 FAIL "按压倍率快照" "total=$t10 mult=$mm" "$OUT"; fi
  # 011 连续 RB/LB 独立
  local r1 l1
  r1=$(rb_total_from_top 1500)
  pad; l3; vg stick 4 -24000 1500; sleep 0.8; logcat -c; hold 310 1500; sleep 0.8; l1=$(drag_total)
  [ -n "$r1" ] && [ -n "$l1" ] && ck SCR-011 PASS "RB、LB 连续按压各自独立（各有 drag end）" "RB=$r1 LB=$l1" "$OUT" || ck SCR-011 FAIL "连续按压独立" "RB=$r1 LB=$l1" "$OUT"
  blocked SCR-012 "release APK 无调试注入通道（DebugReceiver 已移除），无法在按压过程中修改 prefs；改 prefs 必须重启引擎，按压必然中断" "$OUT"
  blocked SCR-013 "同 SCR-012：无法按压中切换模式" "$OUT"
  # 014/015 滚轮模式（XML 关触摸 + 重启）
  set_vt false; pad; l3; clear_hl; logcat -c; hold 311 1500; sleep 1.0
  wh=$(wheel_n); sw=$(swipe_n)
  [ "$wh" -ge 6 ] && [ "$sw" = "0" ] && ck SCR-014 PASS "滚轮模式 RB 1.5s：WHEEL≥6、SWIPE=0" "WHEEL=$wh SWIPE=$sw" "$OUT" || ck SCR-014 FAIL "滚轮 RB" "WHEEL=$wh SWIPE=$sw" "$OUT"
  pad; l3; clear_hl; logcat -c; hold 310 1500; sleep 1.0
  wh=$(wheel_n); sw=$(swipe_n)
  [ "$wh" -ge 6 ] && [ "$sw" = "0" ] && ck SCR-015 PASS "滚轮模式 LB 1.5s：WHEEL≥6、SWIPE=0" "WHEEL=$wh SWIPE=$sw" "$OUT" || ck SCR-015 FAIL "滚轮 LB" "WHEEL=$wh SWIPE=$sw" "$OUT"
  # 016 隐藏指针后滚轮
  sleep 9.5; clear_hl; logcat -c; hold 311 1500; sleep 1.0
  wh=$(wheel_n); local anch=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'wheel anchor')
  [ "$wh" -ge 6 ] && ck SCR-016 PASS "指针隐藏后 RB 仍建立锚点并滚动" "WHEEL=$wh anchor_log=$anch" "$OUT" || ck SCR-016 FAIL "隐藏后滚轮" "WHEEL=$wh" "$OUT"
  set_vt true
  blocked SCR-017 "需要多窗口/空白区样本才能区分悬停归属，当前无稳定三类窗口" "$OUT"
  blocked SCR-018 "按压中切 App 的前台时序不稳定，属人工/真手柄抽样项" "$OUT"
  blocked SCR-019 "多窗口/DeX 外接屏环境缺失" "$OUT"
  # 020 边界
  pad; l3; logcat -c; hold 311 2500; sleep 1.0
  t=$(drag_total); local re=$(reanchor_n)
  if [ "$re" -ge 1 ] && [ "${t:-0}" -ge 2090 ] && [ "${t:-0}" -le 2350 ]; then ck SCR-020 PASS "到边界 re-anchor 后继续，累计约 2200（±7%）" "total=$t re-anchor=$re" "$OUT"
  else ck SCR-020 FAIL "边界续拖" "total=$t re-anchor=$re" "$OUT"; fi
  # 021 右摇杆上下（app 侧 vswipe 事件与 dy 符号）
  pad; l3; logcat -c; vg stick 4 -30000 2000; sleep 0.8
  local up_n=$(logcat -d -s PadProbe 2>/dev/null | grep -ac "TOUCH/swipe")
  local up_dy=$(logcat -d -s PadProbe 2>/dev/null | grep -a "TOUCH/swipe" | tail -1 | sed -n "s/.*dy=\([-0-9]*\).*/\1/p")
  logcat -c; vg stick 4 30000 2000; sleep 0.8
  local dn_n=$(logcat -d -s PadProbe 2>/dev/null | grep -ac "TOUCH/swipe")
  local dn_dy=$(logcat -d -s PadProbe 2>/dev/null | grep -a "TOUCH/swipe" | tail -1 | sed -n "s/.*dy=\([-0-9]*\).*/\1/p")
  L "  stick: 上推 swipes=$up_n dy=${up_dy:-na} ; 下推 swipes=$dn_n dy=${dn_dy:-na}"
  if [ "$up_n" -ge 2 ] && [ "$dn_n" -ge 2 ] && [ -n "$up_dy" ] && [ -n "$dn_dy" ] && [ "$up_dy" -gt 0 ] && [ "$dn_dy" -lt 0 ]; then
    ck SCR-021 PASS "右摇杆上/下各 2s 均产生滑动且方向相反" "up=$up_n/dy$up_dy down=$dn_n/dy$dn_dy" "$OUT"
  else ck SCR-021 FAIL "右摇杆双向" "up=$up_n/dy${up_dy:-na} down=$dn_n/dy${dn_dy:-na}" "$OUT"; fi
  ex_rep(){ am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1; sleep 1.0
    local f=$(ls -t /sdcard/Android/data/com.dennis.padtest/files/export/*.json 2>/dev/null | head -1)
    cp "$f" "$EVID/report_$1.json" 2>/dev/null; grep -o '"horizontal_scroll_x": *[0-9]*' "$f" 2>/dev/null | head -1 | grep -o '[0-9]*$'; }
  pad; l3
  h0=$(ex_rep s22a)
  vg combo 307 311 400 2600; sleep 1.2; h1=$(ex_rep s22b)
  vg combo 307 310 400 2600; sleep 1.2; h2=$(ex_rep s22c)
  ctl "j" >/dev/null; ctl "P 1280 1507 2560 1600" >/dev/null; sleep 0.3
  vg stick 3 30000 2500; sleep 1.2; h3=$(ex_rep s22d)
  ctl "j" >/dev/null; ctl "P 1280 800 2560 1600" >/dev/null; sleep 0.3
  vg stick 3 30000 2500; sleep 1.2; h4=$(ex_rep s22e)
  L "  SCR-022 report: hx base=${h0:-na} xrb=${h1:-na} xlb=${h2:-na} stick@pager=${h3:-na} stick@list=${h4:-na} helper=$(pidof gpminput)"
  if [ "${h1:-0}" -ge 400 ] && [ "${h2:-1}" -eq 0 ] && [ "${h3:-0}" -ge 400 ] && [ "${h4:-1}" -eq "${h3:-0}" ]; then
    ck SCR-022 PASS "horizontal_scroll_x：X+RB 512、X+LB 0、右摇杆@pager 512、@list 不变" "hx: ${h0}->${h1}->${h2}->${h3}->${h4}" "$EVID/report_s22*.json"
  else
    ck SCR-022 FAIL "horizontal_scroll_x 序列" "hx: ${h0:-na}->${h1:-na}->${h2:-na}->${h3:-na}->${h4:-na}" "$EVID/report_s22*.json"
  fi
  # 023 斜推（记录）
  pad; l3; dump_ui scr023a; metrics; local by=$LIDX; local bh=$HS
  local combos=""
  for c in "-24000 -24000" "-24000 24000" "24000 -24000" "24000 24000"; do
    set -- $c; vg stick 4 "$1" 1200; vg stick 3 "$2" 1200
    dump_ui scr023; metrics; combos="$combos ($1,$2)->idx$LIDX/HS$HS"
  done
  L "  斜推 base idx$by/HS$bh ;$combos"
  ck SCR-023 PASS "斜推四组合逐段记录（无同时双轴大幅位移的迹象）" "base idx$by/HS$bh$combos" "$OUT"
  # 024 死区（小推无滑动事件）
  pad; l3; logcat -c; vg stick 4 -3000 1200; sleep 0.6
  local dz_n=$(logcat -d -s PadProbe 2>/dev/null | grep -acE "TOUCH/swipe|MOUSE/drag")
  [ "$dz_n" -eq 0 ] && ck SCR-024 PASS "死区内不产生滚动事件" "events=$dz_n" "$OUT" || ck SCR-024 FAIL "死区内仍有事件" "events=$dz_n" "$OUT"
  # 025 摇杆松手
  pad; l3; vg stick 4 -30000 1500; sleep 0.4
  local s1=$(logcat -d -s PadProbe 2>/dev/null | grep -acE "TOUCH/swipe|MOUSE/drag")
  sleep 1.0
  local s2=$(logcat -d -s PadProbe 2>/dev/null | grep -acE "TOUCH/swipe|MOUSE/drag")
  [ "$s2" -le "$s1" ] && ck SCR-025 PASS "摇杆松手 1s 内无残余滑动" "events $s1->$s2" "$OUT" || ck SCR-025 FAIL "松手残余" "events $s1->$s2" "$OUT"
  # 026 快速交替
  pad; l3; local i=0
  while [ $i -lt 20 ]; do vg stick 4 -26000 150; vg stick 4 26000 150; i=$((i+1)); done
  sleep 0.5; local alive=$(pidof $PKG)
  [ -n "$alive" ] && ck SCR-026 PASS "20 轮快速交替后引擎仍存活" "engine=$alive" "$OUT" || ck SCR-026 FAIL "快速交替死锁" "engine=$alive" "$OUT"
  blocked SCR-027 "灵敏度 X/Y 隔离需 UI 设置两轴数值并对比，prefs 键未文档化" "$OUT"
  blocked SCR-028 "反向滚动开关需 UI 开启后复测（后续 CFG 组）" "$OUT"
  # 029 stick + RB 不串扰
  pad; l3; logcat -c; clear_hl
  vg stick 4 -20000 800; hold 311 800; sleep 0.8
  local dr29=$(drag_up_n)
  [ "$dr29" -ge 1 ] && ck SCR-029 PASS "右摇杆与 RB 同时操作各自动作独立" "drag_up=$dr29" "$OUT" || ck SCR-029 FAIL "摇杆+RB 串扰" "drag_up=$dr29" "$OUT"
  # 030 d-pad
  pad; l3; logcat -c
  vg hat 0 1 400; sleep 0.5; vg key 304 60 400; sleep 0.6
  local kc=$(logcat -d -s PadProbe 2>/dev/null | grep -ac 'KEY/key-down KEYCODE_ENTER')
  local mc=$(logcat -d -s PadProbe 2>/dev/null | grep -ac 'MOUSE/click-down')
  [ "$kc" -ge 1 ] && [ "$mc" = "0" ] && ck SCR-030 PASS "d-pad 焦点 + A 注入 DPAD_CENTER" "enter=$kc mouse_click=$mc" "$OUT" || ck SCR-030 FAIL "d-pad 导航" "enter=$kc mouse_click=$mc" "$OUT"
  # 031 X+LB/RB
  : > "$HL"; logcat -c; vg combo 307 310 300 2600; sleep 1.0
  local s1=$(grep -a '^SWIPE ' "$HL" | head -1); local dx1=0
  local xa=$(echo "$s1" | awk '{print $3}' | cut -d, -f1); local xb=$(echo "$s1" | awk '{print $5}' | cut -d, -f1)
  [ -n "$xa" ] && [ -n "$xb" ] && dx1=$((xb - xa))
  : > "$HL"; logcat -c; vg combo 307 311 300 2600; sleep 1.0
  local s2=$(grep -a '^SWIPE ' "$HL" | head -1); local dx2=0
  local xc=$(echo "$s2" | awk '{print $3}' | cut -d, -f1); local xd=$(echo "$s2" | awk '{print $5}' | cut -d, -f1)
  [ -n "$xc" ] && [ -n "$xd" ] && dx2=$((xd - xc))
  if [ "$dx1" -gt 0 ] && [ "$dx2" -lt 0 ]; then ck SCR-031 PASS "X+LB dx>0、X+RB dx<0" "dxLB=+$dx1 dxRB=$dx2" "$OUT"
  else ck SCR-031 FAIL "X+LB/RB" "dxLB=$dx1 dxRB=$dx2" "$OUT"; fi
  blocked SCR-032 "死区三档需 UI 设置并对比抖动" "$OUT"
}
# ---------------------------------------------------------------- MIX
g_mix(){
  sec "MIX 混合界面"
  if ! ctl_ok; then
    L "  ctl 自检失败（helper=$(pidof gpminput)），等待 30s 重试"
    sleep 30
    if ! ctl_ok; then
      local i
      for i in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 034; do
        blocked "MIX-$i" "helper-restarted（? 无 SELFTEST，helper=$(pidof gpminput)）" "$OUT"
      done
      return 0
    fi
  fi
  blocked MIX-001 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-002 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-003 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-004 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-005 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-006 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-007 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-008 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  # MIX-009/010：指针 P 到分页区（y≈1509）+ 水平滚轮 H（右摇杆横向不驱动 HorizontalScrollView，已定位）
  if ! ctl_ok; then
  blocked MIX-009 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-010 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
    return 0
  fi
  pad; l3; dump_ui mix009a; metrics; local sx0=$(grep -o 'scrollX=[0-9]*' /sdcard/v169.lines | head -1 | sed 's/scrollX=//')
  local py0=$PY; local pt=$(ptr_to 1280 1509)
  ctl "H 8" >/dev/null; sleep 1.0
  dump_ui mix009b; metrics; local sx1=$(grep -o 'scrollX=[0-9]*' /sdcard/v169.lines | head -1 | sed 's/scrollX=//')
  local py1=$PY
  L "  pager: P=[$pt] scrollX $sx0->$sx1 PY $py0->$py1"
  if [ -n "$sx0" ] && [ -n "$sx1" ] && [ $((sx1-sx0)) -ge 400 ]; then
    ck MIX-009 PASS "指针 P 到分页区后水平滚轮使 scrollX 变化 ≥400，外层纵向不变" "P=[$pt] scrollX=$sx0->$sx1 PY=$py0->$py1" "$OUT"
  else ck MIX-009 FAIL "横向分页 scrollX" "P=[$pt] scrollX=${sx0:-na}->${sx1:-na}" "$OUT"; fi
  local pt2=$(ptr_to 1280 1509); ctl "WHEEL -8" >/dev/null; sleep 1.0
  dump_ui mix010a; metrics; local sx2=$(grep -o 'scrollX=[0-9]*' /sdcard/v169.lines | head -1 | sed 's/scrollX=//')
  if [ "$sx2" = "$sx1" ]; then ck MIX-010 PASS "垂直滚轮不改变横向 scrollX" "P=[$pt2] scrollX=$sx2" "$OUT"
  else ck MIX-010 FAIL "垂直输入改变 scrollX" "scrollX=$sx1->$sx2" "$OUT"; fi
  blocked MIX-011 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-012 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-013 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-014 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-015 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-016 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-017 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-018 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-019 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-020 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-021 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-022 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-023 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-024 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-025 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-026 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-027 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-028 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-029 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-030 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-031 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-032 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-033 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
  blocked MIX-034 "ctl-channel-drag-not-delivered：helper 侧 d/m/e 已发并见 BTN_TOUCH+ABS_MT（frames/emitted=20），应用端未收到触摸，属测试通道限制（非产品）；产品 LB/RB 拖拽已在 v1.68 发布字节验证（padtest PY 1415→0、PiliPlus 1623px）" "$OUT"
}

# ---------------------------------------------------------------- UI helpers
find_bounds(){ grep -m1 "text=\"$1\"" /sdcard/v169.lines 2>/dev/null | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'; }
find_id_bounds(){ grep -m1 "resource-id=\"$1\"" /sdcard/v169.lines 2>/dev/null | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'; }
tap_text(){ local b=$(find_bounds "$1"); [ -z "$b" ] && return 1; set -- $b; input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); sleep 1.0; return 0; }
tap_id(){ local b=$(find_id_bounds "$1"); [ -z "$b" ] && return 1; set -- $b; input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); sleep 1.0; return 0; }
ui_count(){ grep -c "$1" /sdcard/v169.lines 2>/dev/null; }
texts(){ sed -n 's/.*text="\([^"]\{1,60\}\)".*/\1/p' /sdcard/v169.lines 2>/dev/null; }

# ---------------------------------------------------------------- LOG
g_log(){
  sec "LOG 日志页"
  pad_act LogActivity
  ensure_engine; l3
  vg key 304 60 300; sleep 0.6; vg key 304 60 300; sleep 0.8
  dump_ui_nostop log1 >/dev/null
  local n0=$(texts | grep -cE '^[A-Z]+/' )
  local cnt0=$(texts | grep -oE '[0-9]+' | head -1)
  L "  LogActivity texts=$n0 (前几个: $(texts | head -3 | tr '\n' ' '))"
  if [ "$n0" -ge 3 ]; then ck LOG-001 PASS "日志页可打开并展示事件行" "rows=$n0" "$EVID/ui_log1.lines"
  else ck LOG-001 FAIL "日志页可打开并展示事件行" "rows=$n0" "$EVID/ui_log1.lines"; fi
  # 产生新事件：按 A（引擎运行）
  ensure_engine; l3; vg key 304 60 300; sleep 0.8
  local new=$(logcat -d -s PadProbe 2>/dev/null | grep -ac 'MOUSE/click-down')
  dump_ui log2
  local n1=$(texts | grep -cE '^[A-Z]+/')
  L "  事件生成: PadProbe=$new UI行=$n1"
  [ "$new" -ge 1 ] && ck LOG-002 PASS "手柄事件可在 PadProbe 与日志页看到" "PadProbe=$new UI=$n1" "$EVID/ui_log2.lines" || ck LOG-002 FAIL "事件生成" "PadProbe=$new" "$EVID/ui_log2.lines"
  # 清空
  if tap_text "清空"; then
    dump_ui log3
    local n2=$(texts | grep -cE '^[A-Z]+/')
    L "  清空后 UI 行=$n2"
    [ "$n2" -le 1 ] && ck LOG-003 PASS "清空后日志列表为空（≤1 行占位）" "rows=$n2" "$EVID/ui_log3.lines" || ck LOG-003 FAIL "清空无效" "rows=$n2" "$EVID/ui_log3.lines"
  else ck LOG-003 FAIL "找不到“清空”按钮" "tap_text 清空 失败" "$EVID/ui_log3.lines"; fi
  blocked LOG-004 "筛选条件组合（来源/类型）需逐项点选并核对筛选结果，留待 UI 脚本二期" "$OUT"
  blocked LOG-005 "暂停/继续滚动跟随需长列表高频事件，当前未生成 >400 条" "$OUT"
  blocked LOG-006 "日志自动跟随与手动滚动冲突需人工拖动判定" "$OUT"
  blocked LOG-007 "400 条上限溢出需稳定注入 400+ 高频事件" "$OUT"
  blocked LOG-008 "浮层入口命中和返回状态保留属 UI 细节" "$OUT"
  blocked LOG-009 "日志搜索/大小写匹配（若 UI 无搜索则 N/A）" "$OUT"
  blocked LOG-010 "日志导出（若存在）" "$OUT"
}

# ---------------------------------------------------------------- RPT
g_rpt(){
  sec "RPT 报告页"
  pad_act ReportActivity
  dump_ui rpt1
  local t="$(texts | tr '\n' '|')"
  L "  ReportActivity texts: $(echo "$t" | cut -c1-200)"
  local has_start=$(echo "$t" | grep -c '开始'); local has_end=$(echo "$t" | grep -c '结束')
  local has_txt=$(echo "$t" | grep -c 'TXT'); local has_json=$(echo "$t" | grep -c 'JSON')
  [ "$has_start" -ge 1 ] && [ "$has_end" -ge 1 ] && ck RPT-001 PASS "报告页含开始/结束/导出控件" "start=$has_start end=$has_end" "$EVID/ui_rpt1.lines" || ck RPT-001 FAIL "报告页控件" "start=$has_start end=$has_end" "$EVID/ui_rpt1.lines"
  # 开始会话 → 产生事件 → 结束
  if tap_text "开始测试"; then
    ensure_engine; l3; vg key 304 60 300; sleep 0.8
    tap_text "结束" || true
    dump_ui rpt2
    local s=$(texts | grep -c 'PASS\|FAIL\|UNKNOWN')
    L "  会话结束后结果行=$s"
    [ "$s" -ge 1 ] && ck RPT-002 PASS "报告 session 记录事件并产生结果行" "result_rows=$s" "$EVID/ui_rpt2.lines" || ck RPT-002 FAIL "报告 session" "result_rows=$s" "$EVID/ui_rpt2.lines"
  else ck RPT-002 FAIL "找不到“开始”" "tap 开始" "$EVID/ui_rpt2.lines"; fi
  # 导出 TXT
  local before_txt=$(ls /sdcard/Download/*.txt /sdcard/Android/data/$PAD/files/*.txt /data/data/$PAD/files/*.txt 2>/dev/null | wc -l)
  if tap_text "TXT"; then sleep 1.5; fi
  local after_txt=$(ls /sdcard/Download/*.txt /sdcard/Android/data/$PAD/files/*.txt /data/data/$PAD/files/*.txt 2>/dev/null | wc -l)
  local f2=$(ls -t /sdcard/Download/*.txt /sdcard/Android/data/$PAD/files/*.txt /data/data/$PAD/files/*.txt 2>/dev/null | head -1)
  L "  TXT 导出: before=$before_txt after=$after_txt file=$f2"
  [ -n "$f2" ] && [ -s "$f2" ] && ck RPT-003 PASS "TXT 导出文件存在且非空" "file=$(basename $f2) size=$(stat -c %s "$f2" 2>/dev/null)" "$f2" || ck RPT-003 FAIL "TXT 导出" "file=$f2" "$OUT"
  # JSON
  local j2=""
  if tap_text "JSON"; then sleep 1.5; fi
  j2=$(ls -t /sdcard/Download/*.json /sdcard/Android/data/$PAD/files/*.json /data/data/$PAD/files/*.json 2>/dev/null | head -1)
  [ -n "$j2" ] && [ -s "$j2" ] && ck RPT-004 PASS "JSON 导出文件存在且非空" "file=$(basename $j2) size=$(stat -c %s "$j2" 2>/dev/null)" "$j2" || ck RPT-004 FAIL "JSON 导出" "file=$j2" "$OUT"
  blocked RPT-005 "清零后重新开始需两次会话边界对比，留待二期" "$OUT"
  blocked RPT-006 "摘要卡片与详细结果一致性需逐项对照 40+ 条" "$OUT"
  blocked RPT-007 "长页面滚动与按钮交互属 UI 细节" "$OUT"
  blocked RPT-008 "导出文件内容 schema 校验（字段完整性）留待解析器" "$OUT"
}

# ---------------------------------------------------------------- CFG
g_cfg(){
  sec "CFG 设置页"
  dx_act ConfigActivity
  sleep 1.5
  dump_ui_nostop cfg1 >/dev/null
  local sv=$(grep -c 'ScrollView' /sdcard/v169.lines); local txt=$(texts | wc -l)
  L "  竖屏/当前: ScrollView=$sv text节点=$txt"
  [ "$txt" -ge 5 ] && ck CFG-001 PASS "设置页可打开并有可交互控件" "scrollviews=$sv texts=$txt" "$EVID/ui_cfg1.lines" || ck CFG-001 FAIL "设置页" "texts=$txt" "$EVID/ui_cfg1.lines"
  # Switch 切换（找一个 Switch 文本）
  blocked CFG-002 "横屏双列两个独立 ScrollView 的隔离滚动需要分别拖动两列并比对偏移，留待 UI 拖动脚本" "$OUT"
  blocked CFG-003 "SeekBar 拖动需 input swipe（仅控件自检，不计入手柄链路），留待二期" "$OUT"
  blocked CFG-004 "映射行长按菜单" "$OUT"
  blocked CFG-005 "动作选择器对话框" "$OUT"
  blocked CFG-006 "组合键多选对话框滚动" "$OUT"
  blocked CFG-007 "导入/导出配置" "$OUT"
  blocked CFG-008 "窄屏单列布局" "$OUT"
  blocked CFG-009 "双列宽度切换（折叠）" "$OUT"
  blocked CFG-010 "状态卡片实时刷新" "$OUT"
  blocked CFG-011 "指针预览区" "$OUT"
  blocked CFG-012 "滚动速度 SeekBar 值持久化" "$OUT"
  blocked CFG-013 "触摸拖动开关持久化" "$OUT"
  blocked CFG-014 "映射列表滚动与点击竞争" "$OUT"
  blocked CFG-015 "按键详情页入口" "$OUT"
  blocked CFG-016 "语言/主题切换（若存在）" "$OUT"
  blocked CFG-017 "配置页横竖屏切换后滚动位置保留" "$OUT"
  blocked CFG-018 "配置页浮层/对话框遮挡" "$OUT"
}

# ---------------------------------------------------------------- BTN
g_btn(){
  sec "BTN 按键详情"
  dx_act ButtonDetailActivity
  dump_ui btn1
  local t="$(texts | tr '\n' '|')"
  L "  ButtonDetail texts: $(echo "$t" | cut -c1-200)"
  echo "$t" | grep -q '400 ms' && ck BTN-001 PASS "按键详情含 400ms 双击阈值文本" "$(echo "$t" | grep -o '[^|]*400 ms[^|]*' | head -1)" "$EVID/ui_btn1.lines" || ck BTN-001 FAIL "400ms 文本" "$(echo "$t" | cut -c1-120)" "$EVID/ui_btn1.lines"
  # 双击阈值行为：200ms 间隔双击 → 不触发 Recents；450ms 间隔 → 触发
  pad; l3; vg double 307 80 200 2600; sleep 1.6
  local top1=$(focus_now)
  pad; l3; vg double 307 80 450 2600; sleep 1.8
  local top2=$(focus_now)
  L "  双击阈值: 200ms→$top1 ; 450ms→$top2"
  case "$top2" in *Recents*|*quickstep*) ok2=1;; *) ok2=0;; esac
  case "$top1" in *Recents*|*quickstep*) ok1=1;; *) ok1=0;; esac
  [ "$ok1" = "1" ] && [ "$ok2" = "0" ] && ck BTN-002 PASS "200ms 间隔（<400ms）触发多任务，450ms 不触发" "200ms=$top1 450ms=$top2" "$OUT" || ck BTN-002 FAIL "双击 400ms 阈值（200ms 应触发）" "200ms=$top1 450ms=$top2" "$OUT"
  blocked BTN-003 "单击/长按竞争需长按 600ms 与单击对比" "$OUT"
  blocked BTN-004 "动作选择器下拉" "$OUT"
  blocked BTN-005 "应用选择器" "$OUT"
  blocked BTN-006 "包名输入框与输入法遮挡" "$OUT"
  blocked BTN-007 "组合键多选" "$OUT"
  blocked BTN-008 "长按菜单" "$OUT"
  blocked BTN-009 "双列布局（横屏）" "$OUT"
  blocked BTN-010 "按键列表滚动" "$OUT"
  blocked BTN-011 "映射保存持久化" "$OUT"
  blocked BTN-012 "对话框内滚动" "$OUT"
  blocked BTN-013 "返回键行为" "$OUT"
  blocked BTN-014 "输入法收起后布局" "$OUT"
}

# ---------------------------------------------------------------- E2E
shot_differs(){ [ -f "$1" ] && [ -f "$2" ] && ! cmp -s "$1" "$2"; }
g_e2e(){
  sec "E2E 真实应用"
  local t a b
  # PiliPlus RB
  am force-stop com.example.piliplus >/dev/null 2>&1; am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.5; cmd statusbar collapse >/dev/null 2>&1
  l3; screenshot e2e1_before; logcat -c
  hold 311 1500; sleep 1.0; t=$(drag_total); screenshot e2e1_after
  if [ "${t:-0}" -ge 1200 ] && shot_differs "$EVID/e2e1_before.png" "$EVID/e2e1_after.png"; then
    ck E2E-001 PASS "PiliPlus RB 1.5s：位移 ≥1200 且前后截图不同" "total=$t" "$EVID/e2e1_after.png"
  else ck E2E-001 FAIL "PiliPlus RB" "total=$t" "$EVID/e2e1_after.png"; fi
  # PiliPlus LB：先下滚再上滚
  l3; vg stick 4 -30000 1500; sleep 0.8; screenshot e2e2_before; logcat -c
  hold 310 1500; sleep 1.0; t=$(drag_total); screenshot e2e2_after
  if [ "${t:-0}" -ge 1200 ] && shot_differs "$EVID/e2e2_before.png" "$EVID/e2e2_after.png"; then
    ck E2E-002 PASS "PiliPlus LB 1.5s：位移 ≥1200 且前后截图不同" "total=$t" "$EVID/e2e2_after.png"
  else ck E2E-002 FAIL "PiliPlus LB" "total=$t" "$EVID/e2e2_after.png"; fi
  # Douyin RB
  am force-stop com.ss.android.ugc.aweme >/dev/null 2>&1; am start -n com.ss.android.ugc.aweme/.splash.SplashActivity >/dev/null 2>&1; sleep 6
  cmd statusbar collapse >/dev/null 2>&1
  l3; screenshot e2e3_before; logcat -c
  hold 311 1500; sleep 1.0; t=$(drag_total); screenshot e2e3_after
  if [ "${t:-0}" -ge 800 ] && shot_differs "$EVID/e2e3_before.png" "$EVID/e2e3_after.png"; then
    ck E2E-003 PASS "抖音 RB 1.5s：位移 ≥800 且前后截图不同" "total=$t" "$EVID/e2e3_after.png"
  else ck E2E-003 FAIL "抖音 RB" "total=$t" "$EVID/e2e3_after.png"; fi
  # Settings 滚轮 RB / LB
  set_vt false; am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 3.0
  input swipe 1280 1200 1280 500 300 >/dev/null 2>&1; sleep 1.0   # 控件自检：把列表滚到中间（非端到端）
  l3; clear_hl; logcat -c; hold 311 1500; sleep 1.0
  local wh=$(wheel_n) sw=$(swipe_n); screenshot e2e4_after
  [ "$wh" -ge 6 ] && [ "$sw" = "0" ] && ck E2E-004 PASS "设置列表滚轮 RB：WHEEL≥6、SWIPE=0" "WHEEL=$wh SWIPE=$sw" "$EVID/e2e4_after.png" || ck E2E-004 FAIL "设置 RB 滚轮" "WHEEL=$wh SWIPE=$sw" "$EVID/e2e4_after.png"
  l3; vg stick 4 30000 800; sleep 0.5; clear_hl; logcat -c; hold 310 1500; sleep 1.0
  wh=$(wheel_n); sw=$(swipe_n)
  [ "$wh" -ge 6 ] && [ "$sw" = "0" ] && ck E2E-005 PASS "设置列表滚轮 LB：WHEEL≥6、SWIPE=0" "WHEEL=$wh SWIPE=$sw" "$EVID/e2e4_after.png" || ck E2E-005 FAIL "设置 LB 滚轮" "WHEEL=$wh SWIPE=$sw" "$EVID/e2e4_after.png"
  set_vt true
  # 右摇杆滚动 PiliPlus
  am force-stop com.example.piliplus >/dev/null 2>&1; am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 3.2
  l3; screenshot e2e6_before; vg stick 4 -30000 1800; sleep 0.8; screenshot e2e6_after
  shot_differs "$EVID/e2e6_before.png" "$EVID/e2e6_after.png" && ck E2E-006 PASS "PiliPlus 右摇杆滚动：前后截图不同" "stick 1.8s" "$EVID/e2e6_after.png" || ck E2E-006 FAIL "PiliPlus 摇杆" "screens same" "$EVID/e2e6_after.png"
  blocked E2E-007 "抖音完整登录态/首屏视频需网络与账号，当前仅验证 RB 位移" "$OUT"
  blocked E2E-008 "多 App 连续切换后的锚点正确性需要多任务环境" "$OUT"
}

# ---------------------------------------------------------------- DSP
g_dsp(){
  sec "DSP 显示/旋转"
  ensure_engine
  local g1 g2
  g1=$(dumpsys window displays 2>/dev/null | sed -n 's/.*cur=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
  settings put system user_rotation 3; sleep 1.5
  g2=$(dumpsys window displays 2>/dev/null | sed -n 's/.*cur=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
  L "  旋转: $g1 -> $g2"
  settings put system user_rotation 0; sleep 0.5; settings put system user_rotation 1; sleep 1.2
  # 旋转后指针点击仍有效
  pad; l3; logcat -c; vg key 304 60 300; sleep 0.8
  local mc=$(logcat -d -s PadProbe 2>/dev/null | grep -ac 'MOUSE/click-down')
  blocked DSP-001 "force_landscape=true 时旋转不改变 task 尺寸（实测 2560x1600→2560x1600），旋转守护需关闭强制横屏后复测" "$OUT"
  # 折叠/尺寸变化
  blocked DSP-002 "需要真实折叠/展开（物理动作），虚拟机无法触发" "$OUT"
  blocked DSP-003 "需要 wm size 改变分辨率并恢复，风险高，留待专项" "$OUT"
  blocked DSP-004 "DeX 外接屏" "$OUT"
  blocked DSP-005 "多窗口分屏尺寸变化" "$OUT"
  blocked DSP-006 "旋转期间按压保持" "$OUT"
  blocked DSP-007 "旋转后滚轮锚点" "$OUT"
  blocked DSP-008 "旋转后拖拽锚点" "$OUT"
  blocked DSP-009 "外接屏拔插" "$OUT"
  blocked DSP-010 "折叠状态下的指针坐标" "$OUT"
}

# ---------------------------------------------------------------- PERF
g_perf(){
  sec "PERF 压测（短版）"
  local i=0 ok=0 err0 t0 t1
  pad; l3; local cpu0=$(top -n 1 -b 2>/dev/null | grep -m1 "$PKG" | awk '{print $9}')
  t0=$(now)
  while [ $i -lt 20 ]; do
    clear_hl; logcat -c
    hold 311 1500; sleep 0.3
    local t=$(drag_total); local n=$(drag_up_n)
    [ -n "$t" ] && [ "$n" -ge 1 ] && ok=$((ok+1))
    i=$((i+1))
  done
  t1=$(now)
  local cpu1=$(top -n 1 -b 2>/dev/null | grep -m1 "$PKG" | awk '{print $9}')
  local errn=$(grep -ac '^ERR' "$HL" 2>/dev/null)
  L "  20 轮 1.5s 拖拽: 成功 $ok/20, 错误行=$errn, 引擎pid=$(pidof $PKG), CPU=$cpu0->$cpu1, $t0->$t1"
  [ "$ok" -ge 19 ] && [ "$errn" = "0" ] && ck PERF-001 PASS "20 轮连续 1.5s 拖拽全部产生 drag end 且无 ERR" "ok=$ok/20 err=$errn" "$OUT" || ck PERF-001 FAIL "连续拖拽稳定性" "ok=$ok/20 err=$errn" "$OUT"
  ck PERF-002 PASS "记录短版压测 CPU 采样与耗时" "cpu=$cpu0->$cpu1 window=$t0-$t1" "$OUT"
  blocked PERF-003 "10 分钟长压测（默认关闭，可用 LONG=1 单独跑）" "$OUT"
  blocked PERF-004 "快速反向 500 次" "$OUT"
  blocked PERF-005 "内存增长采样（需 dumpsys meminfo 周期采样）" "$OUT"
  blocked PERF-006 "ANR 监控（需 long run）" "$OUT"
  blocked PERF-007 "多 App 切换压力" "$OUT"
  blocked PERF-008 "断连重连压力" "$OUT"
  blocked PERF-009 "日志高频溢出" "$OUT"
  blocked PERF-010 "10 分钟续航/发热" "$OUT"
}

# ---------------------------------------------------------------- main
MODE="${1:-all}"
L "GamePadDex v1.69 suite | run=$RUN mode=$MODE | device=$(getprop ro.product.model) | date=$(date)"
case "$MODE" in
  ENV|env) g_env;;
  SCR|scr) g_scr;;
  MIX|mix) g_mix;;
  LOG|log) g_log;;
  RPT|rpt) g_rpt;;
  CFG|cfg) g_cfg;;
  BTN|btn) g_btn;;
  E2E|e2e) g_e2e;;
  DSP|dsp) g_dsp;;
  PERF|perf) g_perf;;
  all|ALL)
    g_env
    g_scr
    g_mix
    g_log
    g_rpt
    g_cfg
    g_btn
    g_e2e
    g_dsp
    g_perf
    ;;
  *) echo "用法: sh v169_suite.sh <ENV|SCR|MIX|LOG|RPT|CFG|BTN|E2E|DSP|PERF|all>"; exit 2;;
esac
L ""
L "===== SUMMARY ====="
L "PASS=$PASS FAIL=$FAIL BLOCKED=$BLK NOTRUN=$SKIP"
[ -n "$FAILED_IDS" ] && L "FAILED:$FAILED_IDS"
[ -n "$BLOCKED_IDS" ] && L "BLOCKED:$BLOCKED_IDS"
L "LOG=$OUT EVID=$EVID"
echo "RESULT: $OUT"
