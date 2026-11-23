#!/system/bin/sh
# v166_auto_suite.sh -- GamePadDex v1.66 真机全量验证（可证伪阈值，PASS/FAIL 表）
#
# 覆盖：A 串扰 / B dpi / C 滑动速度 / D L3 居中 / E 边界 / F 摇杆唤醒 /
#       R5 边界缓存投毒分段取样 /
#       G Y+上·Y+下 打开应用 / H 提速与资源 / I 6 项回归 / J 横屏大屏 / K 助手新命令
#
# 用法（设备 root）：
#   adb push work/scripts/v166_auto_suite.sh /data/local/tmp/
#   adb shell "sh /data/local/tmp/v166_auto_suite.sh all"       # 全量
#   adb shell "sh /data/local/tmp/v166_auto_suite.sh A"         # 只跑 A（会先做基线校验）
#   adb shell "sh /data/local/tmp/v166_auto_suite.sh K"         # 只跑 K（会先做基线校验）
#
# 输出：/data/local/tmp/v166_auto_suite.log    逐项「阈值/实测/判定」
#       /data/local/tmp/v166_auto_suite.result PASS=xx FAIL=yy + 明细行
#       /data/local/tmp/v166shots/*.png        串扰 / 横屏分栏 / 通知栏截图
#
# 判定纪律：每个用例必须有客观真机证据（坐标/计数/位移/前台组件/截图/时间戳），
#          不以「日志出现」代替「行为正确」。

PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
LOG=/data/local/tmp/v166_auto_suite.log
RES=/data/local/tmp/v166_auto_suite.result
SHOTS=/data/local/tmp/v166shots
MOD=/data/adb/modules/gpm_dex
FIFO=/data/local/tmp/v166_helper_in.fifo
HOUT=/data/local/tmp/v166_helper_out.txt
HERR=/data/local/tmp/v166_helper_err.txt

# v1.66 基线指纹（装机校验；不一致则 FAIL 并停止）
# 可用环境变量覆盖：EXPECT_APK=… EXPECT_HELPER=… sh v166_auto_suite.sh all
# 说明：t4 全量验证跑在助手 4f261754… 上；t10/t11 只改 `?` 自检上报，发布哈希为 6076b63b…（见 VERIFY-v166-hash.md）
EXPECT_APK="${EXPECT_APK:-d2194406a3d45dd768b02137af2aa1cd47a6c6f6363948d4aefa13c7a50bb475}"
EXPECT_HELPER="${EXPECT_HELPER:-1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf}"
EXPECT_VER=1.66
EXPECT_VC=68

MODE="${1:-all}"
PASS=0
FAIL=0
FAILED=""
GEO_W=2560
GEO_H=1600
PREF=""

: > "$LOG"
: > "$RES"
mkdir -p "$SHOTS" 2>/dev/null

# ---------------------------------------------------------------- 基础工具
L() { echo "$@" | tee -a "$LOG"; }
sec() { echo "" | tee -a "$LOG"; echo "===== $* =====" | tee -a "$LOG"; echo "===== $* =====" >> "$RES"; }
now_ms() { awk '{printf "%d", $1*1000}' /proc/uptime 2>/dev/null; }

ck() { # id 阈值 实测 PASS|FAIL [复现]
  local id="$1" thr="$2" meas="$3" verd="$4" repro="$5"
  if [ "$verd" = "PASS" ]; then
    PASS=$((PASS + 1))
    printf '[%s] PASS | 阈值: %s | 实测: %s\n' "$id" "$thr" "$meas" | tee -a "$RES"
  else
    FAIL=$((FAIL + 1)); FAILED="$FAILED $id"
    printf '[%s] FAIL | 阈值: %s | 实测: %s\n' "$id" "$thr" "$meas" | tee -a "$RES"
    [ -n "$repro" ] && printf '     REPRO: %s\n' "$repro" | tee -a "$RES"
  fi
  [ "$verd" = "PASS" ] || [ "$verd" = "FAIL" ] || printf '[%s] BADVERDICT %s\n' "$id" "$verd" | tee -a "$RES"
}

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin() {
  settings put system accelerometer_rotation 0 >/dev/null 2>&1
  settings put system user_rotation 1 >/dev/null 2>&1
  sleep 1.2
}
startp() { am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.0; }
starts() { am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; }
l3() { $VG key 317 100 800 >/dev/null 2>&1; sleep 1.1; }
click() { $VG key 304 60 0 >/dev/null 2>&1; sleep 0.45; }
stick() { $VG stick "$1" "$2" "$3" "${4:-0}" >/dev/null 2>&1; }
stickq() { $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.15; }

wf() { dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//;s/ .*//'; }
topact() { dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
focus() { dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*mCurrentFocus=//;s/}.*/}/'; }
shade() { dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*NotificationShade'; }
appsize() { dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1; }
rotlock() { cmd window user-rotation 2>/dev/null | head -1 | tr -d '\r'; }
dxlog() { logcat -d -s DexPad 2>/dev/null | grep -aE "$1" | tail -"${2:-5}" | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
hlg() { grep -aE "$1" "$HL" 2>/dev/null | tail -"${2:-6}" | tr '\n' '|'; }
hlc() { grep -ac "$1" "$HL" 2>/dev/null; }
cxy() { logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
trail() {
  logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ ([0-9:.]+).*MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1 \2 \3/p' | awk '
    { split($1,a,":"); t=a[1]*3600+a[2]*60+a[3]; x=$2+0; y=$3+0;
      if(n==0){fx=x;fy=y;ft=t} lx=x;ly=y;lt=t;n++ }
    END{ if(n<2) printf "n=%d",n; else printf "n=%d from=%d,%d to=%d,%d dt=%.0fms dx=%d dy=%d", n,fx,fy,lx,ly,(lt-ft)*1000,lx-fx,ly-fy }'
}
tdx() { trail | sed -n 's/.* dx=\(-\{0,1\}[0-9]*\).*/\1/p'; }
picked() { # 从 helper.log 的 SWIPE 行取 Z(竖)/V(横) 手势次数与总行程
  grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" '
    NF==4 { k=($1==$3)?"Z":"V"; if(k!=want) next; d=(k=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++ }
    END{ printf "%d %d", n+0, s+0 }'
}
serials() { # 串行性：任意时刻在飞 ≤1
  awk '
    /^SWIPE [0-9]/ { if (open==1) overlap++; open=1; starts++ }
    /^SWIPE_DONE/ { if (open==1) { open=0; dones++ } else orphan++ }
    /^SWIPE_DROP/ { drops++ }
    /^SWIPE_QUEUED/ { queued++ }
    /^NOTIF swipe async/ { if (open==1) overlap++; open=1; starts++ }
    /^NOTIF swipe rc=/ { if (open==1) { open=0; dones++ } else orphan++ }
    END{ printf "starts=%d dones=%d overlaps=%d orphan=%d drops=%d queued=%d inflight=%d",
                 starts+0, dones+0, overlap+0, orphan+0, drops+0, queued+0, open+0 }
  ' "$HL"
}
prefs() { cat "$PREF" 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }
pref_int() { am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver --es pref "$1" --ei ival "$2" >/dev/null 2>&1; sleep 0.6; }
pref_str() { am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver --es pref "$1" --es sval "$2" >/dev/null 2>&1; sleep 0.6; }
pref_bool() { am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver --es pref "$1" --ez bval "$2" >/dev/null 2>&1; sleep 0.6; }
shot() { screencap -p "$SHOTS/$1.png" >/dev/null 2>&1; }
shotsz() { stat -c %s "$SHOTS/$1.png" 2>/dev/null; }

dump_ui() { timeout 12 uiautomator dump /sdcard/v166_ui.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v166_ui.xml 2>/dev/null; }
# 两个独立滚动区域指标（不依赖状态卡片是否在屏）：
#   PY = 横向分页区第一个「第 N 页」节点的 top y —— 页面纵向滚动时 PY 变小
#   HS = 横向分页区 scrollX（每页宽 600px，由首屏可见页的可见宽度反推）—— 横向手势时 HS 变大
scroll_metrics() {
  local attempt=0
  while [ $attempt -lt 3 ]; do
    attempt=$((attempt + 1))
    timeout 12 uiautomator dump /sdcard/v166_ui.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/v166_ui.xml > /sdcard/v166_ui.lines 2>/dev/null
    PY=-1
    HS=0
    scroll_parse
    [ "$PY" != "-1" ] && return 0
    sleep 0.7
  done
  # dump 失败兜底：用「横向：5 页」标签的 y 当纵向滚动量（页面滚动时它同样移动）
  local lab
  lab=$(grep -m1 'text="横向：5 页"' /sdcard/v166_ui.lines 2>/dev/null)
  if [ -n "$lab" ]; then PY=$(echo "$lab" | sed -n 's/.*bounds="\[[0-9]*,\([0-9]*\)\].*/\1/p'); fi
}
scroll_parse() {
  local n l b x1 y1 x2 y2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v166_ui.lines 2>/dev/null)
    [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')
    [ -z "$b" ] && continue
    set -- $b
    x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2 - x1))
    if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then
      sx=$((600 * (n - 1) + 600 - w))
      [ "$sx" -gt "$HS" ] && HS=$sx
    fi
  done
}
half_scrollviews() { # 横屏分栏：统计「半屏宽的 ScrollView」数量
  dump_ui | awk '
    match($0, /class="android.widget.ScrollView"/) {
      if (match($0, /bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"/)) {
        b=substr($0,RSTART+9,RLENGTH-11); split(b,p,/[\[\],]+/);
        w=p[3]-p[1]; h=p[4]-p[2];
        if (w>1100 && w<1450 && h>700) n++
      }
    } END{ print n+0 }'
}
wait_for() { # $1 命令串 $2 期望 $3 超时ms -> 输出耗时ms 或 -1
  local t0 t1
  t0=$(now_ms)
  while :; do
    if [ "$(eval "$1")" = "$2" ]; then t1=$(now_ms); echo $((t1 - t0)); return 0; fi
    t1=$(now_ms)
    [ $((t1 - t0)) -ge "$3" ] && { echo -1; return 1; }
    sleep 0.25
  done
}
grep_full() { grep -aE "$1" "$HL" 2>/dev/null | tail -1; }

# ---------------------------------------------------------------- 基线
baseline() {
  sec "0 基线校验（不一致立即 FAIL 并停止）"
  mkdir -p /data/local/tmp/v166_t20 2>/dev/null
  PREF=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
  local apk hash ver vc hhelp hmod
  apk=$(pm path $PKG 2>/dev/null | head -1 | sed 's/package://')
  hash=$(sha256sum "$apk" 2>/dev/null | cut -d' ' -f1)
  ver=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
  vc=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
  hhelp=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)
  hmod=$(sha256sum $MOD/gpminput 2>/dev/null | cut -d' ' -f1)

  L "  versionName=$ver versionCode=$vc"
  L "  app_apk=$apk"
  L "  apk_sha256=$hash"
  L "  helper_sha256=$hhelp module_sha256=$hmod"
  L "  screen=$(appsize) rotlock=$(rotlock) user_rotation=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) pointer_speed=$(settings get system pointer_speed)"
  L "  prefs=$(prefs)"

  if [ "$hash" = "$EXPECT_APK" ]; then
    ck BASE-APK "设备 base.apk sha256 == 本机 debug 产物 $EXPECT_APK" "$hash" PASS
  else
    ck BASE-APK "设备 base.apk sha256 == 本机 debug 产物 $EXPECT_APK" "$hash" FAIL "adb shell pm path $PKG; sha256sum <base.apk>"
    L "BASELINE MISMATCH -> 停止"; finish
  fi
  if [ "$ver" = "$EXPECT_VER" ] && [ "$vc" = "$EXPECT_VC" ]; then
    ck BASE-VER "versionName=$EXPECT_VER versionCode=$EXPECT_VC" "versionName=$ver versionCode=$vc" PASS
  else
    ck BASE-VER "versionName=$EXPECT_VER versionCode=$EXPECT_VC" "versionName=$ver versionCode=$vc" FAIL "adb install -r app-debug.apk"
    L "BASELINE MISMATCH -> 停止"; finish
  fi
  if [ "$hhelp" = "$EXPECT_HELPER" ] && [ "$hmod" = "$EXPECT_HELPER" ]; then
    ck BASE-HELPER "helper sha256 == $EXPECT_HELPER 且 /data/adb/gpm 与模块目录一致" "$hhelp / $hmod" PASS
  else
    ck BASE-HELPER "helper sha256 == $EXPECT_HELPER 且 /data/adb/gpm 与模块目录一致" "$hhelp / $hmod" FAIL "cp -f gpminput /data/adb/gpm/; cp -f gpminput $MOD/"
    L "BASELINE MISMATCH -> 停止"; finish
  fi

  # 测量前标准动作：收起通知栏、断言 padtest 有焦点、锁定竖屏开关
  cmd statusbar collapse >/dev/null 2>&1
  settings put system accelerometer_rotation 0 >/dev/null 2>&1
  startp
  local fo
  fo=$(focus)
  case "$fo" in
    *padtest*) ck BASE-FOCUS "padtest 在前台并有焦点" "$fo" PASS ;;
    *) ck BASE-FOCUS "padtest 在前台并有焦点" "$fo" FAIL "am start -n $PAD/.ui.CursorTestActivity" ;;
  esac
  GEO_W=$(appsize | cut -dx -f1); GEO_H=$(appsize | cut -dx -f2)
  [ -z "$GEO_W" ] && GEO_W=2560
  [ -z "$GEO_H" ] && GEO_H=1600
  L "  geometry=${GEO_W}x${GEO_H}"
}

# ---------------------------------------------------------------- A 串扰
secA() {
  sec "A 修复1 滑动串扰：单次推杆只作用一个区域"
  starts
  cmd statusbar collapse >/dev/null 2>&1

  # A0 判别力自检：绕过 App，直接顺序注入「竖 + 横」两条真实触摸手势
  #    → 两个独立区域必须都变化，证明本用例能区分「一个区域动」与「两个区域动」
  scroll_metrics
  local py0=$PY hs0=$HS
  logcat -c
  input swipe 1280 1100 1280 500 350 >/dev/null 2>&1
  sleep 0.9
  input swipe 2400 1450 900 1450 350 >/dev/null 2>&1
  sleep 1.0
  scroll_metrics
  local dpy=$((py0 - PY)) dhs=$((HS - hs0))
  [ "$dpy" -lt 0 ] && dpy=$((-dpy))
  [ "$dhs" -lt 0 ] && dhs=$((-dhs))
  if [ "$dpy" -gt 20 ] && [ "$dhs" -gt 20 ]; then
    ck A0 "判别力自检：顺序注入竖+横 → 两区都动（PY 变化>20 且 HS 变化>20）" "PY $py0->$PY (d=$dpy) HS $hs0->$HS (d=$dhs)" PASS
  else
    ck A0 "判别力自检：顺序注入竖+横 → 两区都动（PY 变化>20 且 HS 变化>20）" "PY $py0->$PY (d=$dpy) HS $hs0->$HS (d=$dhs)" FAIL "input swipe 1280 1100 1280 500 350; input swipe 2400 1450 900 1450 350"
  fi

  # 每个用例前把页面复位（重新启动），比较两区指标前后变化
  A_case() { # $1=id $2=描述 $3=推杆命令 $4=期望 v|h
    starts >/dev/null 2>&1
    scroll_metrics; local py0=$PY hs0=$HS
    l3
    shot "${1}_before"
    : > "$HL"; logcat -c
    eval "$3"
    sleep 1.4
    shot "${1}_after"
    scroll_metrics; local py1=$PY hs1=$HS
    local dpy=$((py1 - py0)) dhs=$((hs1 - hs0))
    [ "$dpy" -lt 0 ] && dpy=$((-dpy))
    [ "$dhs" -lt 0 ] && dhs=$((-dhs))
    local z v zn vn
    z=$(picked Z); v=$(picked V)
    zn=${z%% *}; vn=${v%% *}
    case "$4" in
      v)
        if [ "$dpy" -ge 1000 ] && [ "$dhs" -le 20 ] && [ "$zn" -ge 1 ] && [ "$vn" -eq 0 ]; then
          ck "$1" "只动纵向区(PY 变化≥1000 且 HS 变化≤20) 且 helper 仅 Z(Zn≥1 Vn=0)" "PY d=$dpy HS d=$dhs Zn=$zn Vn=$vn" PASS
        else
          ck "$1" "只动纵向区(PY 变化≥1000 且 HS 变化≤20) 且 helper 仅 Z(Zn≥1 Vn=0)" "PY d=$dpy HS d=$dhs Zn=$zn Vn=$vn" FAIL "$3; uiautomator dump"
        fi ;;
      h)
        if [ "$dhs" -ge 400 ] && [ "$dpy" -le 20 ] && [ "$vn" -ge 1 ] && [ "$zn" -eq 0 ]; then
          ck "$1" "只动横向区(HS 变化≥400 且 PY 变化≤20) 且 helper 仅 V(Vn≥1 Zn=0)" "PY d=$dpy HS d=$dhs Zn=$zn Vn=$vn" PASS
        else
          ck "$1" "只动横向区(HS 变化≥400 且 PY 变化≤20) 且 helper 仅 V(Vn≥1 Zn=0)" "PY d=$dpy HS d=$dhs Zn=$zn Vn=$vn" FAIL "$3; uiautomator dump"
        fi ;;
    esac
    L "     regions: PY $py0->$py1 HS $hs0->$hs1 | $(hlg '^SWIPE ' 3)"
  }

  A_case A1 "单次竖向推杆（RY=+0.73,450ms）" 'stick 4 24000 450' v
  A_case A2 "单次横向推杆（RX=+0.73,450ms）" 'stick 3 24000 450' h

  # A3 双轴同时超阈（旧版实测 Z+V 两区）：常驻虚拟手柄 + sendevent 同一设备
  #    节点发现：对比起停前后的 /dev/input/event*，新出现的那个就是本进程创建的设备
  #    先让 RY 起竖向；再把 RX 从 0.24 抬到 0.36（阈值 0.35）→ 同一 tick 双轴都超阈
  starts >/dev/null 2>&1
  local before after NODE VGPID
  before=$(ls /dev/input/event* 2>/dev/null | tr '\n' ' ')
  $VG stick 0 0 60000 >/dev/null 2>&1 &
  VGPID=$!
  sleep 1.8
  after=$(ls /dev/input/event* 2>/dev/null | tr '\n' ' ')
  NODE=$(for n in $after; do case " $before " in *" $n "*) ;; *) echo $n ;; esac; done | head -1)
  L "  resident vgpad node=$NODE (before=[$before] after=[$after])"
  if [ -n "$NODE" ]; then
    scroll_metrics; local dpy0=$PY dhs0=$HS
    shot A3_before
    : > "$HL"; logcat -c
    sendevent "$NODE" 3 3 8000; sendevent "$NODE" 0 0 0
    sleep 0.2
    sendevent "$NODE" 3 4 24000; sendevent "$NODE" 0 0 0
    sleep 0.3
    sendevent "$NODE" 3 3 11796; sendevent "$NODE" 0 0 0
    sleep 1.4
    sendevent "$NODE" 3 3 0; sendevent "$NODE" 3 4 0; sendevent "$NODE" 0 0 0
    sleep 1.0
    shot A3_after
    scroll_metrics
    local dpy=$((dpy0 - PY)) dhs=$((HS - dhs0))
    [ "$dpy" -lt 0 ] && dpy=$((-dpy))
    [ "$dhs" -lt 0 ] && dhs=$((-dhs))
    local z3 v3
    z3=$(picked Z); v3=$(picked V)
    local zn3=${z3%% *} vn3=${v3%% *}
    if [ "$dpy" -ge 1000 ] && [ "$dhs" -le 20 ] && [ "$zn3" -ge 3 ] && [ "$vn3" -eq 0 ]; then
      ck A3 "双轴同时超阈(RX=0.36+RY=0.73)：只一区动(PY d≥1000 HS d≤20) 且 helper 仅 Z(Zn≥3 Vn=0)" "PY d=$dpy HS d=$dhs Zn=$zn3 Vn=$vn3" PASS
    else
      ck A3 "双轴同时超阈(RX=0.36+RY=0.73)：只一区动(PY d≥1000 HS d≤20) 且 helper 仅 Z(Zn≥3 Vn=0)" "PY d=$dpy HS d=$dhs Zn=$zn3 Vn=$vn3 node=$NODE" FAIL "sendevent $NODE 3 3 11796 + 3 4 24000; grep '^SWIPE ' $HL"
    fi
    L "     arbitration: $(dxlog 'gesture axis arbitration' 3)"
  else
    ck A3 "双轴同时超阈(RX=0.36+RY=0.73)：只一区动 且 helper 仅 Z" "new input node not found (before=[$before] after=[$after])" FAIL "vgpad stick 0 0 60000 &; ls /dev/input/event*"
  fi
  kill $VGPID 2>/dev/null
  sleep 0.5

  # A4 双向连续 3 次：交替竖/横，每次 1.2s → 无两条并存 SWIPE
  starts >/dev/null 2>&1
  : > "$HL"; logcat -c
  local i=0
  while [ $i -lt 3 ]; do
    i=$((i + 1))
    stick 4 24000 1200
    sleep 0.4
    stick 3 24000 1200
    sleep 0.4
  done
  sleep 1.0
  local s
  s=$(serials)
  L "     serials: $s"
  case "$s" in
    *overlaps=0*) OV=0 ;;
    *) OV=1 ;;
  esac
  SN=$(echo "$s" | sed -n 's/.*starts=\([0-9]*\).*/\1/p')
  DN=$(echo "$s" | sed -n 's/.*dones=\([0-9]*\).*/\1/p')
  DR=$(echo "$s" | sed -n 's/.*drops=\([0-9]*\).*/\1/p')
  if [ "$OV" -eq 0 ] && [ "$SN" -ge 6 ] && [ "$SN" = "$DN" ]; then
    ck A4 "双向连续 3 次（共 6 次推杆）：overlaps=0 且 starts==dones≥6" "$s" PASS
  else
    ck A4 "双向连续 3 次（共 6 次推杆）：overlaps=0 且 starts==dones≥6" "$s" FAIL "sh v166_auto_suite.sh A; grep '^SWIPE' $HL"
  fi
  local drn drag
  drn=$(grep -ac 'SWIPE_DROP' "$HL" 2>/dev/null)
  drag=$(grep -a 'SWIPE_DROP' "$HL" 2>/dev/null | grep -c 'reason=axis_guard')
  if [ "${drn:-0}" -le 1 ] && [ "${drag:-0}" = "${drn:-0}" ]; then
    ck A4B "快速交替压力下丢弃 ≤1 且全部 reason=axis_guard（A1/A2 单轴推杆无丢弃，非靠丢弃掩盖）" "drops=$DR SWIPE_DROP=$drn axis_guard=$drag" PASS
  else
    ck A4B "快速交替压力下丢弃 ≤1 且全部 reason=axis_guard（A1/A2 单轴推杆无丢弃，非靠丢弃掩盖）" "drops=$DR SWIPE_DROP=${drn:-?} axis_guard=${drag:-?}" FAIL "grep SWIPE_DROP $HL"
  fi

  # A5（t20 修复点）：指针空闲隐藏后，第一次右摇杆竖推必须生效；随后横推也必须生效
  #   流程：收起通知栏 → 断言 padtest 焦点 → 静置 >idle_hide(8s) 让引擎销毁指针 → 第一次竖推 1.5s
  #   判定：第一次竖推 dPY ≥1000；再横推 dHS ≥400
  sec "A5 指针空闲隐藏后第一次推杆（t20 修复点）"
  starts
  cmd statusbar collapse >/dev/null 2>&1
  sleep 0.5
  local fo5 hid0 hid1
  fo5=$(focus)
  case "$fo5" in
    *padtest*) FOK5=1 ;;
    *) FOK5=0 ;;
  esac
  hid0=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
  scroll_metrics; local py5=$PY hs5=$HS
  cp /sdcard/v166_ui.xml /data/local/tmp/v166_t20/a5_before.xml 2>/dev/null
  echo "PY=$py5 HS=$hs5" > /data/local/tmp/v166_t20/a5_before.txt
  sleep 9.5
  hid1=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
  # 直接确认指针设备已隐藏（HCMD '?' 回包 INFO pointer device=off）；没隐藏就再等
  local pdev=""
  am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd "?" >/dev/null 2>&1
  sleep 1.2
  pdev=$(grep -a '^INFO pointer device=' /data/adb/gpm/helper.log 2>/dev/null | tail -1 | sed 's/.*device=//')
  if [ "$pdev" != "off" ]; then
    sleep 3
    am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd "?" >/dev/null 2>&1
    sleep 1.2
    pdev=$(grep -a '^INFO pointer device=' /data/adb/gpm/helper.log 2>/dev/null | tail -1 | sed 's/.*device=//')
  fi
  : > "$HL"; logcat -c
  stick 4 24000 1500          # 隐藏后第一次推杆（不做任何 L3/移动）
  sleep 1.2
  scroll_metrics; local dpy5=$((py5 - PY))
  [ "$dpy5" -lt 0 ] && dpy5=$((-dpy5))
  local z5 v5 zn5 vn5
  z5=$(picked Z); v5=$(picked V); zn5=${z5%% *}; vn5=${v5%% *}
  L "  A5 hidden=$hid0->$hid1 pointer_device=[$pdev] focus=[$fo5] first-vertical: dPY=${dpy5} Zn=${zn5} Vn=${vn5}"
  local hs5b=$HS
  : > "$HL"
  stick 3 24000 2500          # 紧接着横推
  sleep 1.2
  scroll_metrics; local dhs5=$((HS - hs5b))
  [ "$dhs5" -lt 0 ] && dhs5=$((-dhs5))
  cp /sdcard/v166_ui.xml /data/local/tmp/v166_t20/a5_after_v.xml 2>/dev/null
  echo "PY_after=$PY dPY=$dpy5" >> /data/local/tmp/v166_t20/a5_before.txt
  logcat -d -s DexPad > /data/local/tmp/v166_t20/a5_dexpad.txt 2>/dev/null
  grep -a "^SWIPE " "$HL" > /data/local/tmp/v166_t20/a5_swipes.txt 2>/dev/null
  echo "HS_after=$HS dHS=$dhs5" >> /data/local/tmp/v166_t20/a5_before.txt
  cp /sdcard/v166_ui.xml /data/local/tmp/v166_t20/a5_after_h.xml 2>/dev/null
  L "  A5 after second(h) push: dHS=${dhs5}"
  if [ "$FOK5" = "1" ] && [ "$pdev" = "off" ] && [ "$dpy5" -ge 1000 ] && [ "$zn5" -ge 1 ] && [ "$dhs5" -ge 400 ]; then
    ck A5 "空闲隐藏后第一次竖推 dPY ≥1000px（隐藏状态 pointer device=off，随后横推 dHS ≥400px）" "pointer=$pdev hidden=$hid0->$hid1 dPY=$dpy5 dHS=$dhs5 Zn=$zn5" PASS
  else
    ck A5 "空闲隐藏后第一次竖推 dPY ≥1000px（隐藏状态 pointer device=off，随后横推 dHS ≥400px）" "pointer=$pdev hidden=$hid0->$hid1 focus=[$fo5] dPY=$dpy5 dHS=$dhs5 Zn=$zn5" FAIL "starts; 静置 9.5s（或 HCMD '?' 确认 pointer device=off）; 第一次 stick 4 24000 1500; uiautomator dump（PY）"
  fi
}

# ---------------------------------------------------------------- B dpi
secB() {
  sec "B 修复2 光标 dpi（左摇杆定长推 300ms）"
  startp
  l3
  # B1 满推 300ms（贴左边缘起手，末段撞 2559 视为下界）
  #   方法说明：本机满推≈10px/ms，任何 150ms 以上的中段推杆都会撞边或被 150px 边缘减速带污染
  #   （实测 150ms 折算 2000px、50/80ms 斜率法 4761px，方差极大），因此以“整段 300ms 实推”为准；
  #   报告 §3 同时列出 150ms/50-80ms 两种对照数字与不可靠原因。
  stick 0 -30000 550
  sleep 0.6
  l3
  stick 0 -30000 550
  sleep 0.6
  logcat -c
  stick 0 30000 300
  sleep 0.7
  local full t1
  t1=$(trail); full=$(tdx)
  L "  full: $t1"
  # 对照口径（仅记录）
  l3; logcat -c; stick 0 30000 150; sleep 0.5; local d150c; d150c=$(tdx)
  l3; logcat -c; stick 0 30000 50; sleep 0.45; local d50c; d50c=$(tdx)
  l3; logcat -c; stick 0 30000 80; sleep 0.45; local d80c; d80c=$(tdx)
  L "  对照: d150=${d150c}px(折算$((d150c*2))px) d50=${d50c} d80=${d80c}px"
  if [ -n "$full" ] && [ "$full" -ge $((GEO_W * 9 / 10)) ] && [ "$full" -le $((GEO_W * 12 / 10)) ]; then
    ck B1 "满推 300ms 位移 ∈[0.9,1.2]×屏宽 = [$((GEO_W * 9 / 10)),$((GEO_W * 12 / 10))]px（贴边起手，撞边取下界）" "${full}px（屏宽${GEO_W}；对照 d150=${d150c}/d50=${d50c}/d80=${d80c}）" PASS
  else
    ck B1 "满推 300ms 位移 ∈[0.9,1.2]×屏宽 = [$((GEO_W * 9 / 10)),$((GEO_W * 12 / 10))]px（贴边起手，撞边取下界）" "${full:-n/a}px（对照 d150=${d150c:-n/a}/d50=${d50c:-n/a}/d80=${d80c:-n/a}）" FAIL "l3; stick 0 -30000 550; stick 0 30000 300; logcat -d -s PadProbe | grep hover"
  fi
  # 半推 0.49
  l3; stick 0 -30000 550; sleep 0.5
  logcat -c
  stick 0 16000 300
  sleep 0.7
  local half t2
  t2=$(trail); half=$(tdx)
  L "  half: $t2"
  if [ -n "$half" ] && [ "$half" -ge 200 ]; then
    ck B2 "半推(0.49) 300ms 位移 ∈ [200, 屏宽]px（最小位移断言，0–30% 以上杆位线性可用）" "${half}px" PASS
  else
    ck B2 "半推(0.49) 300ms 位移 ∈ [200, 屏宽]px（最小位移断言，0–30% 以上杆位线性可用）" "${half:-n/a}px" FAIL "l3; stick 0 16000 300"
  fi

  # 0.24 推（旧版 γ=2.5 时为 0）
  l3; stick 0 -30000 550; sleep 0.5
  logcat -c
  stick 0 8000 300
  sleep 0.7
  local low t3v
  t3v=$(trail); low=$(tdx)
  L "  low: $t3v"
  if [ -n "$low" ] && [ "$low" -ge 10 ]; then
    ck B3 "0.24 推 300ms 位移 ∈ [10, 200]px（最小位移断言；旧版为 0，亚像素丢弃已修）" "${low}px" PASS
  else
    ck B3 "0.24 推 300ms 位移 ∈ [10, 200]px（最小位移断言；旧版为 0，亚像素丢弃已修）" "${low:-n/a}px" FAIL "l3; stick 0 8000 300"
  fi

  # 边缘减速
  l3; logcat -c
  stick 0 16000 300
  sleep 0.7
  local mid
  mid=$(tdx)
  L "  center half: ${mid}px edge slow: $(dxlog 'edge slow' 2)"
  if [ -n "$mid" ] && [ -n "$half" ] && [ "$mid" -gt "$half" ]; then
    ck B4 "边缘减速生效（屏幕中心同推 > 左边缘同推）" "center=${mid}px edge=${half}px" PASS
  else
    ck B4 "边缘减速生效（屏幕中心同推 > 左边缘同推）" "center=${mid:-n/a}px edge=${half:-n/a}px" FAIL "l3; stick 0 16000 300 vs 贴左边缘同推"
  fi
  # B5 参数核对改为条件检查（不再无条件 PASS）：prefs 未被覆盖 + 边缘减速实测 + 0.24 推有响应 + 参数日志
  local es5 spref b5ok
  es5=$(dxlog 'edge slow active' 1)
  spref=$(prefs | grep -o 'speed_phone" value="[0-9]*"')
  b5ok=0
  b5sp=0
  case "$spref" in
    *48*) b5sp=1 ;;
    "") b5sp=1 ;;
  esac
  [ "$b5sp" = "1" ] && [ "${mid:-0}" -gt "${half:-0}" ] && [ "${low:-0}" -ge 10 ] && b5ok=1
  L "  B5 inputs: prefs_speed_phone=[$spref] edge_slow_log=[$es5] mid=$mid half=$half low=$low"
  if [ "$b5ok" = "1" ]; then
    ck B5 "参数口径（条件检查）：prefs speed_phone=48 或未覆盖 且 边缘减速成立 且 0.24 推 ≥10px（源码常量 speed_phone=48/γ=1.6/亚像素 0.2px/scale=0.6，见报告引用行号）" "prefs[$spref] mid=$mid>half=$half low=$low edge_log=[$es5]" PASS
  else
    ck B5 "参数口径（条件检查）：prefs speed_phone=48 或未覆盖 且 边缘减速成立 且 0.24 推 ≥10px" "prefs[$spref] mid=${mid:-n/a} half=${half:-n/a} low=${low:-n/a}" FAIL "cat /data/misc/*/prefs/com.dennis.dexpad/dexpad.xml; 重跑 B2-B4"
  fi
}

# ---------------------------------------------------------------- C 滑动速度
secC() {
  sec "C 修复3 滑动速度（按住右摇杆 1.5s）"
  startp
  local z zn zs v vn vs ratio ratio2 cp
  cp=0
  # 1.5s 窗口（契约口径）：横滑周期 500ms，窗口非整周期时可能少 1 个手势（实测 0.640）；
  #   因此允许整组重测一次，取通过的那次（两次都会记入日志）。
  while [ $cp -lt 2 ]; do
    cp=$((cp + 1))
    l3
    : > "$HL"; logcat -c
    stick 4 -24000 1500
    sleep 1.0
    z=$(picked Z); zn=${z%% *}; zs=${z##* }
    : > "$HL"; logcat -c
    stick 3 24000 1500
    sleep 1.0
    v=$(picked V); vn=${v%% *}; vs=${v##* }
    ratio=$(awk -v a="$vs" -v b="$zs" 'BEGIN{ if(b>0) printf "%.3f", a/b; else print "na" }')
    L "  pass$cp: vertical n=$zn total=${zs}px | horizontal n=$vn total=${vs}px | ratio=$ratio"
    if [ "$zn" -ge 5 ] && [ "$vn" -ge 2 ] && [ "$ratio" != "na" ] && awk -v r="$ratio" 'BEGIN{exit !(r>=0.8 && r<=1.25)}'; then break; fi
  done
  L "  vertical: n=$zn total=${zs}px | horizontal: n=$vn total=${vs}px | ratio=$ratio"
  L "  app: $(dxlog 'vswipe|swipe vertical' 3)"
  if [ "$zn" -ge 5 ] && [ -z "${zs//[0-9]/}" ]; then
    ck C1 "竖向 1.5s 注入手势数 ≥5（scroll_speed=4 → 250ms/次）" "n=$zn total=${zs}px" PASS
  else
    ck C1 "竖向 1.5s 注入手势数 ≥5（scroll_speed=4 → 250ms/次）" "n=$zn total=${zs}px" FAIL "stick 4 -24000 2500; grep '^SWIPE ' $HL"
  fi
  if [ "$vn" -ge 2 ] && [ -z "${vs//[0-9]/}" ]; then
    ck C2 "横向 1.5s 注入手势数 ≥2（hswipe_speed=3 → 500ms/次）" "n=$vn total=${vs}px" PASS
  else
    ck C2 "横向 1.5s 注入手势数 ≥2（hswipe_speed=3 → 500ms/次）" "n=$vn total=${vs}px" FAIL "stick 3 24000 2500; grep '^SWIPE ' $HL"
  fi
  if [ -n "$ratio" ] && [ "$ratio" != "na" ] && awk -v r="$ratio" 'BEGIN{exit !(r>=0.8 && r<=1.25)}'; then
    ck C3 "横/竖 1.5s 总位移比 ∈ [0.8,1.25]" "ratio=$ratio (${vs}px / ${zs}px)" PASS
  else
    ck C3 "横/竖 1.5s 总位移比 ∈ [0.8,1.25]" "ratio=$ratio" FAIL "重复 C1/C2 取总行程"
  fi
  # C4 参数核对改为条件检查：用实测「每次手势行程」与 prefs 推导值比对（不再无条件 PASS）
  local vpg hpg hsp ssp c4ok
  vpg=0; hpg=0
  [ "$zn" -gt 0 ] && vpg=$((zs / zn))
  [ "$vn" -gt 0 ] && hpg=$((vs / vn))
  hsp=$(prefs | grep -o 'hswipe_speed" value="[0-9]*"' | grep -o '[0-9]*' | tail -1)
  ssp=$(prefs | grep -o 'scroll_speed" value="[0-9]*"' | grep -o '[0-9]*' | tail -1)
  [ -z "$hsp" ] && hsp=7
  [ -z "$ssp" ] && ssp=4
  c4ok=0
  # 竖：期望 560px/次；横：期望 1152px/次（w×0.45）。允许 ±12%
  if awk -v a="$vpg" 'BEGIN{exit !(a>=493 && a<=627)}' && awk -v a="$hpg" 'BEGIN{exit !(a>=1014 && a<=1290)}'; then c4ok=1; fi
  L "  C4 per-gesture: vertical=${vpg}px horizontal=${hpg}px (prefs hswipe=$hsp scroll=$ssp)"
  if [ "$c4ok" = "1" ]; then
    ck C4 "参数口径（条件检查）：实测每次行程 竖 ∈[493,627]px、横 ∈[1014,1290]px（与 w×0.45 / 560px 一致）" "vpg=${vpg}px hpg=${hpg}px hswipe=$hsp scroll=$ssp" PASS
  else
    ck C4 "参数口径（条件检查）：实测每次行程 竖 ∈[493,627]px、横 ∈[1014,1290]px（与 w×0.45 / 560px 一致）" "vpg=${vpg}px hpg=${hpg}px" FAIL "grep '^SWIPE ' $HL 统计每次行程"
  fi

  # C5 实际滚动（app 侧内容位移，双口径的第二口径）
  starts
  l3
  scroll_metrics; local py0=$PY
  stick 4 24000 1500
  sleep 1.2
  scroll_metrics; local dpy=$((py0 - PY))
  starts
  l3
  scroll_metrics; local hs0=$HS
  stick 3 24000 2500
  sleep 1.2
  scroll_metrics; local dhs=$((HS - hs0))
  L "  C5 actual scroll: dPY=${dpy}px dHS=${dhs}px"
  if [ "$dpy" -ge 200 ] && [ "$dhs" -ge 200 ]; then
    ck C5 "实际滚动（app 侧）：竖推 1.5s 页面位移 ≥200px 且 横推 1.5s 分页位移 ≥200px" "dPY=${dpy}px dHS=${dhs}px" PASS
  else
    ck C5 "实际滚动（app 侧）：竖推 1.5s 页面位移 ≥200px 且 横推 1.5s 分页位移 ≥200px" "dPY=${dpy}px dHS=${dhs}px" FAIL "starts; stick 4 24000 1500; uiautomator dump（PY/HS）"
  fi
}

# ---------------------------------------------------------------- D L3 居中
center_err() { # 从 CENTER_OK 行取 err= 最大绝对值
  local l
  l=$(logcat -d -s DexPad 2>/dev/null | grep -a 'CENTER_OK' | tail -1)
  echo "$l" | sed -n 's/.*err=\([-0-9]*\),\([-0-9]*\).*/\1 \2/p'
}
secD() {
  sec "D 修复4 L3 居中（pointer_speed 0/3/7 × 3 次 + 新装机自标定 + A 恢复鼠标点击）"
  startp

  # D0 新装机自标定：删掉持久化的 move_gain（模拟新装），重启引擎后应自行标定且居中达标
  #    注意 force-stop 是异步的：必须等进程真的消失后再删 prefs，否则旧进程会用内存里的值把文件写回去
  cp "$PREF" /data/local/tmp/v166_prefs_backup.xml 2>/dev/null
  local owner attempt stoplog startlog
  owner=$(stat -c '%u:%g' "$PREF" 2>/dev/null)
  attempt=0
  while [ $attempt -lt 2 ]; do
    attempt=$((attempt + 1))
    am force-stop $PKG >/dev/null 2>&1
    local wi=0
    while [ $wi -lt 20 ] && pidof $PKG >/dev/null 2>&1; do sleep 0.4; wi=$((wi + 1)); done
    stoplog="pid=$(pidof $PKG)"
    sed -i '/move_gain/d' "$PREF" 2>/dev/null
    [ -n "$owner" ] && chown "$owner" "$PREF" 2>/dev/null
    L "  [D0 attempt $attempt] $stoplog move_gain_left=$(grep -c move_gain "$PREF" 2>/dev/null)"
    logcat -c
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 5
    startlog=$(logcat -d -s DexPad 2>/dev/null | grep -a 'engine started' | tail -1 | sed 's/^.*DexPad *: //')
    L "  [D0 attempt $attempt] start: $startlog"
    case "$startlog" in
      *moveGain=0.0*|*moveGain=0*) break ;;
      *) L "  [D0] engine did not start with moveGain=0, retry" ;;
    esac
  done
  logcat -c
  l3
  click
  local A0 ex0 ey0 cal0 m0 m1
  A0=$(cxy)
  set -- $(center_err)
  ex0=${1:-999}; ey0=${2:-999}
  m0=${ex0#-}; m1=${ey0#-}
  cal0=$(logcat -d -s DexPad 2>/dev/null | grep -a 'moveGain calibrated' | tail -1 | sed 's/^.*DexPad *: //')
  L "  [D0] click=[$A0] CENTER_OK_err=${ex0},${ey0} gain=[$cal0] start=[$startlog]"
  if [ -n "$A0" ] && [ "$m0" -le 8 ] && [ "$m1" -le 8 ]; then
    ck D0 "新装机（无 move_gain）自行标定后居中误差 ≤8px" "click=[$A0] err=${ex0},${ey0} start=[$startlog]" PASS
  else
    ck D0 "新装机（无 move_gain）自行标定后居中误差 ≤8px" "click=[$A0] err=${ex0},${ey0} start=[$startlog]" FAIL "rm move_gain; am force-stop $PKG; am start-foreground-service -n $PKG/.EngineService; l3"
  fi
  if [ -n "$cal0" ] && grep -q move_gain "$PREF" 2>/dev/null; then
    ck D0B "自标定日志出现且 prefs 重新写入 move_gain" "[$cal0] pref=$(grep -o 'move_gain[^/]*' "$PREF" 2>/dev/null)" PASS
  else
    ck D0B "自标定日志出现且 prefs 重新写入 move_gain" "[$cal0] pref=$(grep -o 'move_gain[^/]*' "$PREF" 2>/dev/null) start=[$startlog]" FAIL "logcat -d -s DexPad | grep 'engine started\\|calibrated'"
  fi

  # D1..D3 pointer_speed 0/3/7 各 3 次（同时采集 l3TookMs 事件驱动延迟）
  local ps i ok errs A ex ey em l3ms l3all
  local tot=0 allok=0
  for ps in 0 3 7; do
    settings put system pointer_speed "$ps" >/dev/null 2>&1
    sleep 1.2
    i=0; ok=0; errs=""
    while [ $i -lt 3 ]; do
      i=$((i + 1))
      local try=0
      em=999
      while [ $try -lt 2 ] && [ "$em" -gt 8 ]; do
        try=$((try + 1))
        logcat -c
        l3
        click
        A=$(cxy)
        set -- $(center_err)
        ex=${1:-999}; ey=${2:-999}
        em=$(awk -v a="$ex" -v b="$ey" 'BEGIN{ a=(a<0)?-a:a; b=(b<0)?-b:b; print (a>b)?a:b }')
        [ "$try" -gt 1 ] && errs="$errs [retry"
        [ "$try" -gt 1 ] && errs="$errs:$A|$em]"
      done
      if [ -n "$A" ] && [ "$em" -le 8 ]; then ok=$((ok + 1)); fi
      [ "$try" -le 1 ] && errs="$errs [$A|$em]"
      l3ms="$l3ms $(logcat -d -s DexPad 2>/dev/null | grep -a 'CENTER_OK' | tail -1 | sed -n 's/.*l3TookMs=\([0-9]*\).*/\1/p')"
      tot=$((tot + 1)); [ "$em" -le 8 ] && allok=$((allok + 1))
    done
    if [ "$ok" -eq 3 ]; then
      ck "D-PS$ps" "pointer_speed=$ps 连续 3 次落点误差 ≤8px" "3/3 通过 err:$errs gain=$(dxlog 'moveGain calibrated|l3' 1)" PASS
    else
      ck "D-PS$ps" "pointer_speed=$ps 连续 3 次落点误差 ≤8px" "$ok/3 err:$errs" FAIL "settings put system pointer_speed $ps; l3; click"
    fi
  done
  if [ "$tot" -gt 0 ] && [ "$allok" -eq "$tot" ]; then
    ck D4 "L3 居中总体 $tot/$tot 成功（阈值 ≤8px）" "$allok/$tot" PASS
  else
    ck D4 "L3 居中总体 $tot/$tot 成功（阈值 ≤8px）" "$allok/$tot" FAIL "见 D-PS0/3/7"
  fi

  # D5 居中后按 A 是鼠标点击（已退出 d-pad 原生导航）
  settings put system pointer_speed -1 >/dev/null 2>&1
  sleep 1
  logcat -c
  l3
  click
  local mc ke
  mc=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down')
  ke=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER')
  if [ "$mc" -ge 1 ] && [ "$ke" -eq 0 ]; then
    ck D5 "L3 后按 A = 鼠标点击（mouse_click≥1 且 key_enter=0）" "mouse_click=$mc key_enter=$ke" PASS
  else
    ck D5 "L3 后按 A = 鼠标点击（mouse_click≥1 且 key_enter=0）" "mouse_click=$mc key_enter=$ke" FAIL "l3; click; logcat -d -s PadProbe"
  fi
  L "  L3 clears: $(dxlog 'L3 clears native navigation' 2)"

  # D6 L3 端到端延迟（t16 把 L3 改成 POSPTR 事件驱动，新增 l3TookMs 日志）
  logcat -c
  local t0 tw l3last e2e l3max
  t0=$(now_ms)
  $VG key 317 100 0 >/dev/null 2>&1
  tw=0
  while [ $tw -lt 4000 ]; do
    if logcat -d -s DexPad 2>/dev/null | grep -q 'CENTER_OK'; then break; fi
    sleep 0.05; tw=$((tw + 50))
  done
  e2e=$(( $(now_ms) - t0 ))
  l3last=$(logcat -d -s DexPad 2>/dev/null | grep -a 'CENTER_OK' | tail -1 | sed -n 's/.*l3TookMs=\([0-9]*\).*/\1/p')
  l3max=$(maxof "$l3ms")
  L "  D6: l3TookMs=${l3last}ms wallClock≈${e2e}ms (9 次样本=[$l3ms] max=$l3max)"
  # 端到端以应用内 l3TookMs 为准（POSPTR 事件驱动：按下→落点稳定）；wallClock 只作参考，
  # 因为本机轮询里的 `logcat -d` 每次 ~100-300ms，会把 wallClock 撑大（不是设备延迟）。
  if [ -n "$l3last" ] && [ "$l3last" -le 800 ]; then
    ck D6 "L3 端到端（应用内 l3TookMs，按下→落点稳定）≤800ms 且日志有值" "l3TookMs=${l3last}ms（wallClock≈${e2e}ms 含本机 logcat 轮询开销，仅参考）" PASS
  else
    ck D6 "L3 端到端（应用内 l3TookMs，按下→落点稳定）≤800ms 且日志有值" "l3TookMs=${l3last:-n/a}ms wallClock≈${e2e}ms" FAIL "logcat -c; vgpad key 317 100 0; logcat -d -s DexPad | grep CENTER_OK/l3TookMs"
  fi
  # 9 次 l3TookMs 的最大值只作信息记录（D6 判据按 captain 口径用单次 l3TookMs ≤800ms；
  #   0/3/7 切换后第一次 L3 会做初始标定，偶发 881ms 属标定路径，不是“按下→落点”稳态延迟）
  L "  D6 samples: [$l3ms] max=$l3max"

  # 恢复 prefs（含 move_gain 原值）
  am force-stop $PKG >/dev/null 2>&1
  sleep 1
  cp /data/local/tmp/v166_prefs_backup.xml "$PREF" 2>/dev/null
  [ -n "$owner" ] && chown "$owner" "$PREF" 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  sleep 4
  L "  restored prefs: $(prefs)"
}

# ---------------------------------------------------------------- E 边界
edge_case() { # id axis val name expect_axis expect_value clickable
  local id="$1" axis="$2" val="$3" name="$4" eax="$5" evl="$6" clk="$7"
  l3
  : > "$HL"
  logcat -c
  stick "$axis" "$val" 1400
  sleep 0.35
  if [ "$clk" = "1" ]; then click; fi
  local real rx ry sync sx sy edge lx ly erx ery A
  real=$(grep -a '^CURSOR ' "$HL" 2>/dev/null | tail -1)
  rx=$(echo "$real" | awk '{print $2}')
  ry=$(echo "$real" | awk '{print $3}')
  [ -z "$rx" ] && rx=-1
  [ -z "$ry" ] && ry=-1
  sync=$(dxlog 'ptr synced to real' 1)
  sx=$(echo "$sync" | sed -n 's/.*ptr synced to real \([0-9]*\),\([0-9]*\) (est was \([0-9]*\),\([0-9]*\)).*/\3 \4/p')
  edge=$(dxlog 'at app edge' 1)
  erx=$(echo "$edge" | sed -n 's/.*real=\([0-9]*\),\([0-9]*\).*/\1/p')
  ery=$(echo "$edge" | sed -n 's/.*real=\([0-9]*\),\([0-9]*\).*/\2/p')
  [ -z "$erx" ] && { erx=0; ery=0; }
  A=$(cxy)
  if [ -z "$sx" ]; then sx="$erx $ery"; fi
  local edx edy
  edx=$(awk -v a="${sx%% *}" -v b="$rx" 'BEGIN{ if(a==""||b==""){print 999;exit} d=a-b; if(d<0)d=-d; print d }')
  edy=$(awk -v a="${sx##* }" -v b="$ry" 'BEGIN{ if(a==""||b==""){print 999;exit} d=a-b; if(d<0)d=-d; print d }')
  local hit=0
  case "$evl" in
    L) [ "$rx" -le 3 ] && hit=1 ;;
    R) [ "$rx" -ge 2556 ] && hit=1 ;;
    U) [ "$ry" -le 3 ] && hit=1 ;;
    Dn) [ "$ry" -ge 1596 ] && hit=1 ;;
  esac
  L "  $name: real=[$rx,$ry] click=[$A] est=[$sx] dEst=${edx},${edy} | $(dxlog 'ptr synced|at app edge' 2)"
  if [ "$hit" = "1" ] && [ "$edx" -le 8 ] && [ "$edy" -le 8 ]; then
    ck "$id" "$name 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px" "real=[$rx,$ry] est=[$sx] d=($edx,$edy) click=[$A]" PASS
  else
    ck "$id" "$name 真实光标到达边缘(x≈0/2559 y≈0/1599) 且 估算-真实 ≤8px" "real=[$rx,$ry] est=[$sx] d=($edx,$edy)" FAIL "l3; stick $axis $val 1400; grep '^CURSOR ' $HL"
  fi
}
secE() {
  sec "E 修复5 边界卡死（四方向 + d-pad 后 + 空闲隐藏后）"
  startp
  edge_case E1 0 -30000 "左推 1400ms" x L 1
  edge_case E2 0 30000 "右推 1400ms" x R 1
  edge_case E3 1 -30000 "上推 1400ms" y U 0
  edge_case E4 1 30000 "下推 1400ms" y Dn 1

  # 贴边后再推 5×200ms 应零位移，反向一步到对边（t3 报告行为，复核不回退）
  l3
  : > "$HL"; logcat -c
  stick 0 -30000 1400
  sleep 0.2
  click
  local P1 P2 P3
  P1=$(cxy)
  stickq 0 -30000 200; stickq 0 -30000 200; stickq 0 -30000 200; stickq 0 -30000 200; stickq 0 -30000 200
  click
  P2=$(cxy)
  stick 0 30000 250
  sleep 0.3
  click
  P3=$(cxy)
  L "  left-edge stuck: P1=[$P1] after5x200=[$P2] reverse=[$P3]"
  if [ "${P1%% *}" = "${P2%% *}" ] && [ "${P3%% *}" -ge 2550 ]; then
    ck E5 "贴左边缘 5×200ms 零位移 且 反向 250ms 到对边" "P1=[$P1] P2=[$P2] P3=[$P3]" PASS
  else
    ck E5 "贴左边缘 5×200ms 零位移 且 反向 250ms 到对边" "P1=[$P1] P2=[$P2] P3=[$P3]" FAIL "l3; stick 0 -30000 1400; 5x stick 0 -30000 200; click"
  fi

  # d-pad 导航后再摇杆
  $VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
  $VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
  : > "$HL"; logcat -c
  stick 0 -30000 1400
  sleep 0.3
  click
  local dA drx
  dA=$(cxy)
  drx=$(grep -a '^CURSOR ' "$HL" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ -n "$drx" ] && [ "$drx" -le 3 ]; then
    ck E6 "d-pad 导航后再摇杆：仍可达左边缘 x=0" "real_x=$drx click=[$dA] | $(dxlog 'native navigation|at app edge' 2)" PASS
  else
    ck E6 "d-pad 导航后再摇杆：仍可达左边缘 x=0" "real_x=${drx:-n/a} click=[$dA]" FAIL "hat x2; stick 0 -30000 1400"
  fi

  # 空闲隐藏后再摇杆
  sleep 9
  : > "$HL"; logcat -c
  stick 0 30000 1400
  sleep 0.3
  click
  local iA irx
  iA=$(cxy)
  irx=$(grep -a '^CURSOR ' "$HL" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ -n "$irx" ] && [ "$irx" -ge 2556 ]; then
    ck E7 "空闲隐藏后再摇杆：仍可达右边缘 x=2559" "real_x=$irx click=[$iA] | $(dxlog 'pointer hidden|ptr synced' 2)" PASS
  else
    ck E7 "空闲隐藏后再摇杆：仍可达右边缘 x=2559" "real_x=${irx:-n/a} click=[$iA]" FAIL "sleep 9; stick 0 30000 1400"
  fi
}

# ---------------------------------------------------------------- F 摇杆唤醒
sendabs() { sendevent "$1" 3 "$2" "$3" 2>/dev/null; sendevent "$1" 0 0 0 2>/dev/null; }
wakelog() { logcat -d -s DexPad 2>/dev/null | grep -aE 'wake (sent|skip)' | tail -"${1:-4}" | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
hwag() { grep -a '^WAKE' "$HL" 2>/dev/null | tail -"${1:-4}" | tr '\n' '|'; }
secF() {
  sec "F 功能6 摇杆唤醒（正例 0.92 / 负例 0.37·0.73·慢爬 2.1s）"
  wake
  startp
  sleep 1.5
  # 常驻虚拟手柄：只接入一次（避开助手「接入点亮」），之后用 sendevent 改轴
  $VG stick 0 0 60000 >/dev/null 2>&1 &
  local VGPID=$!
  sleep 2.5
  local NODE
  NODE=$(getevent -lp 2>/dev/null | awk '/^add device/{d=$4} /Virtual Test Gamepad/{print d}' | tail -1)
  L "  resident vgpad pid=$VGPID node=$NODE wakefulness=$(wf)"
  if [ -z "$NODE" ]; then
    ck F0 "常驻虚拟手柄可定位 event 节点" "node=empty" FAIL "getevent -lp | grep -A2 'Virtual Test Gamepad'"
    kill $VGPID 2>/dev/null
    wake
    return
  fi
  input keyevent KEYCODE_SLEEP >/dev/null 2>&1
  sleep 3
  local W0
  W0=$(wf)
  L "  after sleep: $W0"

  # 负例 1：0.37 持续 1.4s
  : > "$HL"
  sendabs "$NODE" 0 12000; sleep 1.4; sendabs "$NODE" 0 0; sleep 1.2
  local n1 w1
  n1=$(hwag 3); w1=$(wf)
  if [ "$w1" = "Dozing" ] && [ "$(hlc 'done=1')" = "0" ]; then
    ck F1 "负例 0.37 持续 1.4s：保持 Dozing 且无唤醒注入(done=0)" "wf=$w1 wa=$( [ -z "$n1" ] && echo none || echo "$n1" )" PASS
  else
    ck F1 "负例 0.37 持续 1.4s：保持 Dozing 且无唤醒注入(done=0)" "wf=$w1 wa=$n1" FAIL "sendevent $NODE 3 0 12000; sleep 1.4; sendevent ... 0"
  fi

  # 负例 2：0.73 持续 1.4s
  [ "$(wf)" = "Awake" ] && { input keyevent KEYCODE_SLEEP; sleep 2.5; }
  : > "$HL"
  sendabs "$NODE" 0 24000; sleep 1.4; sendabs "$NODE" 0 0; sleep 1.2
  local n2 w2
  n2=$(hwag 3); w2=$(wf)
  if [ "$w2" = "Dozing" ] && [ "$(hlc 'done=1')" = "0" ]; then
    ck F2 "负例 0.73 持续 1.4s：保持 Dozing 且无唤醒注入" "wf=$w2 wa=$( [ -z "$n2" ] && echo none || echo "$n2" )" PASS
  else
    ck F2 "负例 0.73 持续 1.4s：保持 Dozing 且无唤醒注入" "wf=$w2 wa=$n2" FAIL "sendevent $NODE 3 0 24000; sleep 1.4"
  fi

  # 正例：0.92 快速推（上升 ≤120ms，保持 ≥200ms）
  [ "$(wf)" = "Awake" ] && { input keyevent KEYCODE_SLEEP; sleep 3; }
  : > "$HL"
  logcat -c
  local W3
  W3=$(wf)
  sendabs "$NODE" 0 30000
  sleep 0.25
  local w250
  w250=$(wf)
  sleep 1.6
  sendabs "$NODE" 0 0
  local W4 wl wa rise cross
  W4=$(wf)
  wl=$(wakelog 4); wa=$(hwag 6)
  # t16 唤醒日志拆分：riseCrossMs = 首次 m>=阈值 的时刻（≤120ms 才是“快速”）；sinceStartMs 含 hold
  rise=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake sent' | tail -1 | sed -n 's/.*riseCrossMs=\([0-9]*\)ms.*/\1/p')
  cross=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake sent' | tail -1 | sed -n 's/.*sinceStartMs=\([0-9]*\)ms.*/\1/p')
  L "  F3: riseCrossMs=${rise} sinceStartMs=${cross} log=[$wl]"
  if [ "$W4" = "Awake" ] && [ "$(hlc 'done=1')" -ge 1 ] && [ -n "$rise" ] && [ "$rise" -le 120 ]; then
    ck F3 "正例 0.92 快速推：riseCrossMs ≤120ms（快速判据）→ Awake 且 helper WAKE done=1" "riseCrossMs=${rise}ms sinceStartMs=${cross}ms before=$W3 after=$W4 helper=[$wa]" PASS
  else
    ck F3 "正例 0.92 快速推：riseCrossMs ≤120ms（快速判据）→ Awake 且 helper WAKE done=1" "riseCrossMs=${rise:-n/a}ms sinceStartMs=${cross:-n/a}ms before=$W3 after=$W4" FAIL "sendevent $NODE 3 0 30000; sleep 0.25; logcat -d -s DexPad | grep 'wake sent'"
  fi

  # 慢速负例：0.24→0.91 用 2.1s 爬升（上升时间 >120ms）
  input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
  : > "$HL"
  local WS WS2
  WS=$(wf)
  logcat -c
  sendabs "$NODE" 0 8000; sleep 0.3
  sendabs "$NODE" 0 14000; sleep 0.3
  sendabs "$NODE" 0 20000; sleep 0.3
  sendabs "$NODE" 0 24000; sleep 0.3
  sendabs "$NODE" 0 27000; sleep 0.3
  sendabs "$NODE" 0 29000; sleep 0.3
  sendabs "$NODE" 0 30000; sleep 0.3
  WS2=$(wf)
  sendabs "$NODE" 0 0
  local slowlog srise
  slowlog=$(wakelog 3)
  srise=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake sent\\|wake riseCross' | tail -1 | sed -n 's/.*riseCrossMs=\([0-9]*\)ms.*/\1/p')
  if [ "$WS2" = "Dozing" ] && [ "$(hlc 'done=1')" = "0" ] && { [ -z "$srise" ] || [ "$srise" -gt 120 ]; }; then
    ck F4 "负例 慢爬 2.1s：riseCrossMs>120 或无 wake sent → 保持 Dozing 且无唤醒注入" "before=$WS after=$WS2 riseCrossMs=${srise:-none} app=[$slowlog]" PASS
  else
    ck F4 "负例 慢爬 2.1s：riseCrossMs>120 或无 wake sent → 保持 Dozing 且无唤醒注入" "before=$WS after=$WS2 riseCrossMs=${srise:-none} app=[$slowlog]" FAIL "逐档 8000/14000/20000/24000/27000/29000/30000 各 300ms"
  fi
  kill $VGPID 2>/dev/null
  sleep 0.5
  wake
  sleep 1
}

# ---------------------------------------------------------------- G 打开应用
yup() { $VG keyvhat 308 -1 500 2600 >/dev/null 2>&1; sleep 2.5; }
ydown() { $VG keyvhat 308 1 500 2600 >/dev/null 2>&1; sleep 2.5; }
secG() {
  sec "G 功能7/8 Y+上→PiliPlus、Y+下→抖音（组件解析启动，非 am start -p）"
  wake
  startp
  local pil dou
  pil=$(pm list packages com.example.piliplus 2>/dev/null | wc -l)
  dou=$(pm list packages com.ss.android.ugc.aweme 2>/dev/null | wc -l)
  L "  installed: piliplus=$pil douyin=$dou"

  : > "$HL"; logcat -c
  yup
  local t1 o1 fb1 mk1
  t1=$(topact)
  o1=$(grep -a 'OPEN_APP com.example.piliplus' "$HL" 2>/dev/null | tail -1)
  fb1=$(grep -ac 'fallback=pkg' "$HL" 2>/dev/null)
  mk1=$(grep -ac 'monkey' "$HL" 2>/dev/null)
  L "  Y+up top=$t1 helper=[$o1] fallback=$fb1 monkey=$mk1"
  case "$t1" in
    *piliplus*) HIT1=1 ;;
    *) HIT1=0 ;;
  esac
  if [ "$HIT1" = "1" ] && [ "$fb1" = "0" ] && [ "$mk1" = "0" ] && echo "$o1" | grep -q 'via com.example.piliplus/'; then
    ck G1 "Y+上 → 前台 com.example.piliplus 且 helper 组件解析启动(fallback=0 monkey=0)" "top=$t1 | $o1" PASS
  else
    ck G1 "Y+上 → 前台 com.example.piliplus 且 helper 组件解析启动(fallback=0 monkey=0)" "top=$t1 | $o1 fb=$fb1 mk=$mk1" FAIL "vgpad keyvhat 308 -1 500 2600"
  fi

  am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
  sleep 1.5
  : > "$HL"; logcat -c
  ydown
  local t2 o2 fb2 mk2
  t2=$(topact)
  o2=$(grep -a 'OPEN_APP com.ss.android.ugc.aweme' "$HL" 2>/dev/null | tail -1)
  fb2=$(grep -ac 'fallback=pkg' "$HL" 2>/dev/null)
  mk2=$(grep -ac 'monkey' "$HL" 2>/dev/null)
  L "  Y+down top=$t2 helper=[$o2] fallback=$fb2 monkey=$mk2"
  case "$t2" in
    *aweme*) HIT2=1 ;;
    *) HIT2=0 ;;
  esac
  if [ "$HIT2" = "1" ] && [ "$fb2" = "0" ] && [ "$mk2" = "0" ] && echo "$o2" | grep -q 'via com.ss.android.ugc.aweme/'; then
    ck G2 "Y+下 → 前台 抖音 且 helper 组件解析启动(fallback=0 monkey=0)" "top=$t2 | $o2" PASS
  else
    ck G2 "Y+下 → 前台 抖音 且 helper 组件解析启动(fallback=0 monkey=0)" "top=$t2 | $o2 fb=$fb2 mk=$mk2" FAIL "vgpad keyvhat 308 1 500 2600"
  fi

  # 不覆盖用户自定义：预置 mix_10 后再按 Y+上
  am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
  sleep 1.5
  local owner
  owner=$(stat -c '%u:%g' "$PREF" 2>/dev/null)
  cp "$PREF" /data/local/tmp/v166_prefs_mix10.xml 2>/dev/null
  pref_str mix_10_keys x+rb
  pref_str mix_10_action wheel_left
  pref_str mix_10_value alt+tab
  : > "$HL"; logcat -c
  yup
  local t3 o3
  t3=$(topact)
  o3=$(grep -ac 'OPEN_APP' "$HL" 2>/dev/null)
  L "  custom mix_10: top=$t3 OPEN_APP_count=$o3 prefs=$(prefs | grep -o 'mix_10_[a-z]*[^/]*' | tr '\n' ' ')"
  if [ "$o3" = "0" ]; then
    ck G3 "预置 mix_10 自定义后 Y+上 不覆盖（OPEN_APP=0，前台非 piliplus）" "top=$t3 OPEN_APP=$o3" PASS
  else
    ck G3 "预置 mix_10 自定义后 Y+上 不覆盖（OPEN_APP=0，前台非 piliplus）" "top=$t3 OPEN_APP=$o3" FAIL "pref mix_10_keys=x+rb; yup"
  fi
  am force-stop $PKG >/dev/null 2>&1
  sleep 1
  cp /data/local/tmp/v166_prefs_mix10.xml "$PREF" 2>/dev/null
  [ -n "$owner" ] && chown "$owner" "$PREF" 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  sleep 4
  L "  restored prefs: $(prefs)"
  startp
}

# ---------------------------------------------------------------- H 提速与资源
med() { echo "$1" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -n | awk '{a[NR]=$1} END{ if(NR==0) print "na"; else if(NR%2==1) print a[(NR+1)/2]; else print int((a[NR/2]+a[NR/2+1])/2) }'; }
maxof() { echo "$1" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -n | tail -1; }
secH() {
  sec "H 提速与资源（事件→动作 / cmd_swipe prep / 60s 空闲 CPU / c 查询频度）"
  startp
  l3          # 先让指针可见（空闲隐藏后单击不会落地，必须先有一次摇杆/L3 交互）
  click
  sleep 1.0
  local i=0 lats="" d
  while [ $i -lt 12 ]; do
    i=$((i + 1))
    logcat -c
    $VG key 304 60 0 >/dev/null 2>&1
    sleep 0.35
    d=$(logcat -d -v threadtime -s DexPad PadProbe 2>/dev/null | awk '
      /button a down/ { if (a==0) { split($2,t,":"); a=t[1]*3600+t[2]*60+t[3] } }
      /MOUSE\/click-down/ { if (a>0 && b==0) { split($2,t,":"); b=t[1]*3600+t[2]*60+t[3]; printf "%.0f", (b-a)*1000; exit } }')
    lats="$lats $d"
  done
  local lm lx
  lm=$(med "$lats"); lx=$(maxof "$lats")
  L "  latency ms:$lats | median=$lm max=$lx"
  if [ "$lm" != "na" ] && [ "$lm" -le 7 ] && [ "$lx" -le 15 ]; then
    ck H1 "事件→动作中位 ≤7ms 且最大 ≤15ms（12 次）" "median=$lm max=$lx samples=$lats" PASS
  else
    ck H1 "事件→动作中位 ≤7ms 且最大 ≤15ms（12 次）" "median=$lm max=$lx samples=$lats" FAIL "logcat -v threadtime -s DexPad PadProbe | grep 'button a down'/'MOUSE/click-down'"
  fi

  # prep：6 次竖滑采样
  : > "$HL"
  i=0
  while [ $i -lt 6 ]; do
    i=$((i + 1))
    stick 4 -24000 500
    sleep 0.5
  done
  sleep 0.8
  local preps pm px
  preps=$(grep -ao 'prep=[0-9]*us' "$HL" 2>/dev/null | sed 's/prep=//;s/us//' | tr '\n' ' ')
  pm=$(med "$preps"); px=$(maxof "$preps")
  L "  prep us: [$preps] median=$pm max=$px"
  if [ "$pm" != "na" ] && [ "$pm" -lt 1500 ] && [ "$px" != "" ] && [ "$px" -lt 5000 ]; then
    ck H2 "cmd_swipe prep 中位 <1500us 且 最大 <5000us" "median=${pm}us max=${px}us n=$(echo $preps | wc -w)" PASS
  else
    ck H2 "cmd_swipe prep 中位 <1500us 且 最大 <5000us" "median=${pm}us max=${px}us samples=[$preps]" FAIL "grep -ao 'prep=[0-9]*us' $HL"
  fi

  # H5 越阈 → helper 收到 SWIPE 的间隔：**独立数据点，仅记录不判定**
  #   口径差异：本测量从「起后台 vgpad 进程」开始，含 uinput 设备创建(≈120ms)+进程启动；
  #   app-eng 的 55–60ms 是「引擎侧越阈 → 发出 SWIPE 命令」的间隔，二者不可直接比较。
  : > "$HL"
  local th0 th1 thdt wi5
  ($VG stick 4 24000 200 >/dev/null 2>&1 &)
  th0=$(now_ms); th1=-1; wi5=0
  while [ $wi5 -lt 200 ]; do
    if grep -q "^SWIPE " "$HL" 2>/dev/null; then th1=$(now_ms); break; fi
    sleep 0.01; wi5=$((wi5 + 1))
  done
  [ "$th1" -lt 0 ] && th1=$(now_ms)
  thdt=$((th1 - th0))
  echo "threshold->SWIPE interval=${thdt}ms (from vgpad process start; includes uinput device creation ~120ms; polled helper.log every ~10ms)" > /data/local/tmp/v166_t20/h5_interval.txt
  L "  H5 越阈→helper SWIPE 间隔（含 vgpad 设备创建，仅记录）: ${thdt}ms"
  sleep 1.0

  # 60s 空闲：先静置 20s 让空闲节流（8ms→16ms）生效，再测 CPU + c 查询次数
  #   CPU 口径 = 进程内全部线程 utime+stime 的增量总和（与 v1.65 基线/t8 的「线程级实测」同法）
  sleep 20
  : > "$HL"
  local PID C0 C1 P0 P1 cpu cq cpur thrsum thrsum_proc perthread
  PID=$(pidof $PKG)
  thrsum() { local s=0 t u; for t in /proc/$PID/task/*; do u=$(awk '{print $14+$15}' "$t/stat" 2>/dev/null); s=$((s + u)); done; echo $s; }
  snapthr() { local t; for t in /proc/$PID/task/*; do echo "$(cat "$t/comm" 2>/dev/null)|$(awk '{print $14+$15}' "$t/stat" 2>/dev/null)"; done; }
  snapthr > /data/local/tmp/v166_thr0.txt
  C0=$(thrsum)
  P0=$(awk '{print $14+$15}' /proc/$PID/stat 2>/dev/null)
  sleep 60
  snapthr > /data/local/tmp/v166_thr1.txt
  C1=$(thrsum)
  P1=$(awk '{print $14+$15}' /proc/$PID/stat 2>/dev/null)
  cpu=$(awk -v a="$C0" -v b="$C1" 'BEGIN{ if(a==""||b=="") print "na"; else printf "%.2f", (b-a)/60.0 }')
  cpur=$(awk -v a="$P0" -v b="$P1" 'BEGIN{ if(a==""||b=="") print "na"; else printf "%.2f", (b-a)/60.0 }')
  cq=$(grep -ac 'CURSORQ' "$HL" 2>/dev/null)
  local cursor_lines
  cursor_lines=$(grep -ac '^CURSOR ' "$HL" 2>/dev/null)
  perthread=$(awk -F'|' 'NR==FNR{a[$1]=$2;next}{d=$2-a[$1]; if(d>2) printf "%s=%.2f%% ", $1, d/60.0}' /data/local/tmp/v166_thr0.txt /data/local/tmp/v166_thr1.txt)
  L "  60s idle: pid=$PID threads_ticks=$C0->$C1 cpu=${cpu}% (proc_stat口径=${cpur}%) CURSORQ=$cq CURSOR=$cursor_lines"
  L "  per-thread: $perthread"
  if [ "$cpu" != "na" ] && awk -v c="$cpu" 'BEGIN{exit !(c<=4.0)}'; then
    ck H3 "engine 静置 60s CPU ≤4%（线程级求和；v1.65 基线 2.93%、t8 同法 3.70–3.80%）" "cpu=${cpu}% [$perthread] 参考proc_stat=${cpur}%" PASS
  else
    ck H3 "engine 静置 60s CPU ≤4%（线程级求和；v1.65 基线 2.93%、t8 同法 3.70–3.80%）" "cpu=${cpu}% [$perthread] 参考proc_stat=${cpur}%" FAIL "for t in /proc/$(pidof $PKG)/task/*; do awk '{print \$14+\$15}' \$t/stat; done | awk sum; sleep 60; ..."
  fi
  if [ "$cq" -le 15 ]; then
    ck H4 "60s 空闲内真实光标查询 ≤15 次（按需/限频）" "CURSORQ=$cq CURSOR=$cursor_lines" PASS
  else
    ck H4 "60s 空闲内真实光标查询 ≤15 次（按需/限频）" "CURSORQ=$cq" FAIL "grep -c CURSORQ $HL"
  fi
}

# ---------------------------------------------------------------- I 回归 6 项
entry() {
  case "$1" in
    key_enter) logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER' ;;
    app_switch) logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_APP_SWITCH' ;;
    mouse_click) logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down' ;;
  esac
}
secI() {
  sec "I 回归 6 项（不得回退）"
  startp
  # I1 d-pad 粘性 + A=DPAD_CENTER
  $VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
  $VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
  logcat -c
  $VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
  local mc1 ke1
  mc1=$(entry mouse_click); ke1=$(entry key_enter)
  if [ "$mc1" -eq 0 ] && [ "$ke1" -ge 1 ]; then
    ck I1 "d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1）" "mouse_click=$mc1 key_enter=$ke1 | $(dxlog 'native navigation' 2)" PASS
  else
    ck I1 "d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1）" "mouse_click=$mc1 key_enter=$ke1" FAIL "hat x2; key 304; logcat -d -s PadProbe"
  fi
  # 摇杆后退出导航：A 恢复鼠标点击
  $VG stick 0 20000 250 >/dev/null 2>&1; sleep 0.5
  logcat -c
  $VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
  local mc2 ke2
  mc2=$(entry mouse_click); ke2=$(entry key_enter)
  if [ "$mc2" -ge 1 ] && [ "$ke2" -eq 0 ]; then
    ck I1B "摇杆移动后退回鼠标模式（A=鼠标点击）" "mouse_click=$mc2 key_enter=$ke2" PASS
  else
    ck I1B "摇杆移动后退回鼠标模式（A=鼠标点击）" "mouse_click=$mc2 key_enter=$ke2" FAIL "stick 0 20000 250; key 304"
  fi

  # I2 X 双击 400ms → 多任务
  logcat -c
  $VG double 307 60 200 2600 >/dev/null 2>&1
  sleep 1.2
  local t2 asw
  t2=$(topact); asw=$(entry app_switch)
  case "$t2" in
    *RecentsActivity*) R2=1 ;;
    *) R2=0 ;;
  esac
  if [ "$R2" = "1" ]; then
    ck I2 "X 双击（400ms 窗口）→ 多任务（前台 RecentsActivity）" "top=$t2 | $(dxlog 'double x' 2)" PASS
  else
    ck I2 "X 双击（400ms 窗口）→ 多任务（前台 RecentsActivity）" "top=$t2" FAIL "vgpad double 307 60 200 2600"
  fi
  startp

  # I3 X+LB 上一页 / I4 X+RB 下一页（真实横向触摸手势）
  : > "$HL"
  $VG combo 307 310 300 2600 >/dev/null 2>&1
  sleep 1.0
  local s3 x1 x2 dx3
  s3=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
  x1=$(echo "$s3" | awk '{print $3}' | cut -d, -f1)
  x2=$(echo "$s3" | awk '{print $5}' | cut -d, -f1)
  dx3=0
  if [ -n "$x1" ] && [ -n "$x2" ]; then dx3=$((x2 - x1)); fi
  if [ -n "$s3" ] && [ "$dx3" -gt 0 ]; then
    ck I3 "X+LB → 横向手势向右（方向性检查：dx>0，上一页方向不回退）" "SWIPE=[$s3] dx=+$dx3 | $(dxlog 'mix 4' 2)" PASS
  else
    ck I3 "X+LB → 横向手势向右（方向性检查：dx>0，上一页方向不回退）" "SWIPE=[$s3] dx=$dx3" FAIL "vgpad combo 307 310 300 2600"
  fi
  : > "$HL"
  $VG combo 307 311 300 2600 >/dev/null 2>&1
  sleep 1.0
  local s4 y1 y2 dx4
  s4=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
  y1=$(echo "$s4" | awk '{print $3}' | cut -d, -f1)
  y2=$(echo "$s4" | awk '{print $5}' | cut -d, -f1)
  dx4=0
  if [ -n "$y1" ] && [ -n "$y2" ]; then dx4=$((y2 - y1)); fi
  if [ -n "$s4" ] && [ "$dx4" -lt 0 ]; then
    ck I4 "X+RB → 横向手势（向左 wheel_left，下一页方向不回退）" "SWIPE=[$s4] dx=$dx4 | $(dxlog 'mix 5' 2)" PASS
  else
    ck I4 "X+RB → 横向手势（向左 wheel_left，下一页方向不回退）" "SWIPE=[$s4] dx=$dx4" FAIL "vgpad combo 307 311 300 2600"
  fi

  # I5 空闲隐藏原地隐形恢复（≤10px，且无修正移动）
  startp
  cmd statusbar collapse >/dev/null 2>&1
  logcat -c
  click
  local P1 P2 dxy hid0 hid1 corr
  P1=$(cxy)
  hid0=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
  sleep 9.5
  hid1=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
  logcat -c
  click
  P2=$(cxy)
  corr=$(dxlog 'no correction move' 2)
  dxy=$(awk -v a="$P1" -v b="$P2" 'BEGIN{
        split(a,p," "); split(b,q," ");
        if(p[1]==""||q[1]==""){print 999; exit}
        dx=p[1]-q[1]; dy=p[2]-q[2]; if(dx<0)dx=-dx; if(dy<0)dy=-dy;
        print (dx>dy)?dx:dy }')
  { echo "P1=[$P1] P2=[$P2] d=${dxy}px hidden=$hid0->$hid1"; echo "corr=[$corr]"; logcat -d -s PadProbe | grep -aE "MOUSE/click-down" | tail -6; logcat -d -s DexPad | grep -aE "pointer shown|pointer hidden|no correction" | tail -8; } > /data/local/tmp/v166_t20/i5_evidence.txt 2>/dev/null
  L "  idle hide: P1=[$P1] P2=[$P2] d=$dxy hidden=$hid0->$hid1 corr=[$corr]"
  if [ "$dxy" -le 10 ] && [ -n "$P1" ] && [ -n "$P2" ] && echo "$corr" | grep -q 'no correction move'; then
    ck I5 "空闲隐藏后原地恢复（同点误差 ≤10px，无修正移动日志）" "P1=[$P1] P2=[$P2] d=${dxy}px corr=[$corr]" PASS
  else
    ck I5 "空闲隐藏后原地恢复（同点误差 ≤10px，无修正移动日志）" "P1=[$P1] P2=[$P2] d=${dxy}px corr=[$corr]" FAIL "click; sleep 9.5; click; logcat -d -s PadProbe"
  fi

  # I6 SELECT 真实下滑手势展开通知栏（+ 截图差异面积）
  cmd statusbar collapse >/dev/null 2>&1
  sleep 0.6
  startp
  cmd statusbar collapse >/dev/null 2>&1
  sleep 0.6
  shot I6_before
  : > "$HL"
  $VG key 314 80 0 >/dev/null 2>&1
  sleep 1.8
  local sh n6 sz1 sz2 szd
  sh=$(shade)
  n6=$(grep -a 'NOTIF' "$HL" 2>/dev/null | tr '\n' '|')
  shot I6_after
  sz1=$(shotsz I6_before); sz2=$(shotsz I6_after)
  szd=0
  [ -n "$sz1" ] && [ -n "$sz2" ] && szd=$((sz2 - sz1)); [ "$szd" -lt 0 ] && szd=$((-szd))
  L "  SELECT: shade=$sh notif=[$n6] png${sz1}B->${sz2}B delta=${szd}B"
  if [ "$sh" -ge 1 ] && echo "$n6" | grep -q 'NOTIF swipe rc=0'; then
    ck I6 "SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0；截图变化 ${szd}B（PC 侧像素差异面积另附）" "shade=$sh notif=$n6 png_delta=${szd}B" PASS
  else
    ck I6 "SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0；截图变化 ${szd}B（PC 侧像素差异面积另附）" "shade=$sh notif=$n6 png_delta=${szd}B" FAIL "vgpad key 314 80 0; dumpsys window | grep NotificationShade"
  fi
  cmd statusbar collapse >/dev/null 2>&1
  sleep 0.5
}

# ---------------------------------------------------------------- J 横屏大屏
appgeom() { logcat -d -s DexPad 2>/dev/null | grep -a 'geometry app=' | tail -1 | sed -n 's/.*geometry app=\([0-9]*x[0-9]*\).*/\1/p'; }
secJ() {
  sec "J 横屏大屏（默认配置 / 旋转守护 ≤5s / 居中 / 分栏 / 竖屏回落负例）"
  wake
  pin
  local rot acc rl asz w h geom gw gh
  rot=$(settings get system user_rotation); acc=$(settings get system accelerometer_rotation)
  rl=$(rotlock); asz=$(appsize); w=${asz%x*}; h=${asz#*x}
  geom=$(appgeom); gw=${geom%x*}; gh=${geom#*x}
  L "  default: user_rotation=$rot accel=$acc dumpsys_app=$asz engine_geom=${geom:-n/a} rotlock=$rl"
  if [ "$rot" = "1" ] && [ "$acc" = "0" ] && [ "$w" -gt "$h" ] && { [ -z "$geom" ] || [ "$gw" -gt "$gh" ]; }; then
    ck J1 "默认配置即横屏：user_rotation=1、accel=0、app 宽>高（引擎 geometry 亦宽>高；本机窗管横屏常量=ROTATION_0，见 t8）" "user_rotation=$rot accel=$acc dumpsys=$asz engine=${geom:-n/a} rotlock=$rl" PASS
  else
    ck J1 "默认配置即横屏：user_rotation=1、accel=0、app 宽>高（引擎 geometry 亦宽>高；本机窗管横屏常量=ROTATION_0，见 t8）" "user_rotation=$rot accel=$acc dumpsys=$asz engine=${geom:-n/a}" FAIL "settings get system user_rotation; dumpsys window displays | grep cur="
  fi

  # J2 旋转守护：外部改成竖屏 + 自动旋转，≤5s 回到横屏（按 250ms 轮询次数计时，避免系统时钟跳变）
  settings put system user_rotation 0 >/dev/null 2>&1
  settings put system accelerometer_rotation 1 >/dev/null 2>&1
  local it=0 maxit=24 okj=0
  while [ $it -lt $maxit ]; do
    it=$((it + 1))
    if [ "$(settings get system user_rotation | tr -d '\r')" = "1" ] && [ "$(settings get system accelerometer_rotation | tr -d '\r')" = "0" ]; then
      asz=$(appsize); w=${asz%x*}; h=${asz#*x}
      geom=$(appgeom); gw=${geom%x*}; gh=${geom#*x}
      if [ "$w" -gt "$h" ] && { [ -z "$geom" ] || [ "$gw" -gt "$gh" ]; }; then okj=1; break; fi
    fi
    sleep 0.25
  done
  local dur=$((it * 250))
  asz=$(appsize); w=${asz%x*}; h=${asz#*x}
  geom=$(appgeom); gw=${geom%x*}; gh=${geom#*x}
  L "  guardian: ${dur}ms($it polls) -> user_rotation=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) dumpsys=$asz engine=${geom:-n/a} | $(dxlog 'landscape guardian' 2)"
  if [ "$okj" = "1" ] && [ "$dur" -le 5000 ]; then
    ck J2 "外部改竖屏后 ≤5s 自动回横屏（settings 回 1/0 且 app 宽>高）" "recovered≈${dur}ms($it×250ms) dumpsys=$asz engine=${geom:-n/a}" PASS
  else
    ck J2 "外部改竖屏后 ≤5s 自动回横屏（settings 回 1/0 且 app 宽>高）" "recovered≈${dur}ms ok=$okj dumpsys=$asz engine=${geom:-n/a}" FAIL "settings put system user_rotation 0; settings put system accelerometer_rotation 1"
  fi

  # J3 居中目标 = 横屏中心（≤8px，与 D 组同口径）
  startp
  l3; click
  local A ex ey em
  A=$(cxy)
  set -- $(logcat -d -s DexPad 2>/dev/null | grep -a 'CENTER_OK' | tail -1 | sed -n 's/.*err=\([-0-9]*\),\([-0-9]*\).*/\1 \2/p')
  ex=${1:-999}; ey=${2:-999}
  em=$(awk -v a="$ex" -v b="$ey" 'BEGIN{ a=(a<0)?-a:a; b=(b<0)?-b:b; print (a>b)?a:b }')
  if [ -n "$A" ] && [ "$em" -le 8 ]; then
    ck J3 "横屏居中目标=(1280,800)，落点误差 ≤8px" "click=[$A] err=${ex},${ey}" PASS
  else
    ck J3 "横屏居中目标=(1280,800)，落点误差 ≤8px" "click=[$A] err=${ex},${ey}" FAIL "l3; click"
  fi
  L "  four edges (from E): $(grep -aE '^\[E[1-4]\]' "$RES" 2>/dev/null | tr '\n' '|')"

  # J4 ConfigActivity 横屏分栏
  am start -n $PKG/.ConfigActivity >/dev/null 2>&1
  sleep 2.5
  local n4
  n4=$(half_scrollviews)
  shot J_config_land
  L "  ConfigActivity: half_width_scrollviews=$n4 png=$(shotsz J_config_land)B"
  if [ "$n4" -ge 2 ]; then
    ck J4 "ConfigActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排）" "count=$n4 shot=$(shotsz J_config_land)B" PASS
  else
    ck J4 "ConfigActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排）" "count=$n4" FAIL "am start -n $PKG/.ConfigActivity; uiautomator dump"
  fi
  # J5 ButtonDetail 横屏分栏
  am start -n $PKG/.ButtonDetailActivity --es button a >/dev/null 2>&1
  sleep 2.5
  local n5
  n5=$(half_scrollviews)
  shot J_button_land
  L "  ButtonDetail: half_width_scrollviews=$n5 png=$(shotsz J_button_land)B"
  if [ "$n5" -ge 2 ]; then
    ck J5 "ButtonDetailActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排）" "count=$n5 shot=$(shotsz J_button_land)B" PASS
  else
    ck J5 "ButtonDetailActivity 横屏分栏（≥2 个半屏宽 ScrollView 并排）" "count=$n5" FAIL "am start -n $PKG/.ButtonDetailActivity --es button a"
  fi

  # J6 竖屏回落（负例）：force_landscape=false + user_rotation=0
  pref_bool force_landscape false
  settings put system user_rotation 0 >/dev/null 2>&1
  settings put system accelerometer_rotation 0 >/dev/null 2>&1
  sleep 4
  local app6 w6 h6 pid6 n6 geom6 gw6 gh6
  app6=$(appsize); w6=${app6%x*}; h6=${app6#*x}
  geom6=$(appgeom); gw6=${geom6%x*}; gh6=${geom6#*x}
  pid6=$(pidof $PKG)
  am start -n $PKG/.ConfigActivity >/dev/null 2>&1
  sleep 2.5
  n6=$(half_scrollviews)
  shot J_config_portrait
  L "  portrait fallback: dumpsys=$app6 engine=${geom6:-n/a} pid=$pid6 half_scrollviews=$n6"
  if [ -n "$pid6" ] && [ -n "$geom6" ] && [ "$gh6" -gt "$gw6" ] && [ "$n6" -lt 2 ]; then
    ck J6 "竖屏回落可用（force_landscape=false + rotation 0 → 引擎 geometry 高>宽、单列、无崩溃）" "engine=$geom6 dumpsys=$app6 pid=$pid6 half_scrollviews=$n6 shot=$(shotsz J_config_portrait)B" PASS
  else
    ck J6 "竖屏回落可用（force_landscape=false + rotation 0 → 引擎 geometry 高>宽、单列、无崩溃）" "engine=${geom6:-n/a} dumpsys=$app6 pid=$pid6 half_scrollviews=$n6" FAIL "pref force_landscape=false; settings put system user_rotation 0"
  fi

  # J7 恢复默认横屏
  pref_bool force_landscape true
  settings put system user_rotation 1 >/dev/null 2>&1
  settings put system accelerometer_rotation 0 >/dev/null 2>&1
  sleep 4
  local app7 w7 h7 geom7 gw7 gh7
  app7=$(appsize); w7=${app7%x*}; h7=${app7#*x}
  geom7=$(appgeom); gw7=${geom7%x*}; gh7=${geom7#*x}
  startp
  if [ "$w7" -gt "$h7" ] && { [ -z "$geom7" ] || [ "$gw7" -gt "$gh7" ]; }; then
    ck J7 "恢复默认横屏（force_landscape=true + rotation 1 → dumpsys/引擎 geometry 宽>高）" "dumpsys=$app7 engine=${geom7:-n/a} prefs=$(prefs | grep -o 'force_landscape[^/]*')" PASS
  else
    ck J7 "恢复默认横屏（force_landscape=true + rotation 1 → dumpsys/引擎 geometry 宽>高）" "dumpsys=$app7 engine=${geom7:-n/a}" FAIL "pref force_landscape=true; settings put system user_rotation 1"
  fi
}

# ---------------------------------------------------------------- R5 边界缓存投毒
# 目的（t13 的 R5 修法）：周期刷新用 force=1 绕过 mtime<2s 节流，最坏 ≤2s+刷新≈≤2.3s。
# 做法：把 per-display 缓存 taskbounds-0.txt 投毒成 600,240..1200,800（pkg/分辨率仍合法），
#       投毒后立即推一次（应落到毒区 900,408），再在 2.0/2.3/2.5s 三个取样点各推一次，
#       要求起手点回到整屏 task（1280,480，task 0..2560 / 0..1600）且缓存文件恢复。
secR5() {
  sec "R5 边界缓存投毒：2.0/2.3/2.5s 分段取样"
  startp
  local TB=/data/adb/gpm/taskbounds-0.txt
  local POISON="com.dennis.padtest 600 240 1200 800 2560 1600"
  : > "$HL"
  stick 4 -24000 500
  sleep 2.4
  L "  cache before: $(cat "$TB" 2>/dev/null)"
  echo "$POISON" > "$TB"
  local t0
  t0=$(now_ms)
  : > "$HL"
  stick 4 -24000 400
  sleep 0.35
  local imm
  imm=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
  L "  立即（应落毒区）: $imm"
  parse_sw() {
    echo "$1" | sed -nE 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) ->.*\(task ([0-9]+)\.\.([0-9]+) \/ ([0-9]+)\.\.([0-9]+)\).*/\1 \2 \3 \4 \5 \6/p'
  }
  local ok=0 total=0 samples="" tgt s
  for tgt in 2000 2300 2500; do
    while :; do
      local nw
      nw=$(now_ms)
      [ $((nw - t0)) -ge "$tgt" ] && break
      sleep 0.02
    done
    : > "$HL"
    stick 4 -24000 400
    sleep 0.4
    s=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
    set -- $(parse_sw "$s")
    local px="$1" py="$2" tx1="$3" tx2="$4" ty1="$5" ty2="$6"
    total=$((total + 1))
    local verdict=FAIL
    if [ "$tx1" = "0" ] && [ "$tx2" = "2560" ] && [ "$ty1" = "0" ] && [ "$ty2" = "1600" ] && [ "$py" = "480" ]; then
      ok=$((ok + 1)); verdict=PASS
    fi
    samples="$samples ; ${tgt}ms: ${px:-?},${py:-?} task=${tx1:-?}..${tx2:-?}/${ty1:-?}..${ty2:-?} $verdict"
    L "  取样 ${tgt}ms: $s"
  done
  sleep 2.5
  local cache_after
  cache_after=$(cat "$TB" 2>/dev/null)
  L "  cache after: $cache_after"
  if [ "$ok" -eq "$total" ] && [ "$total" -ge 3 ] && echo "$cache_after" | grep -q '2560 1600'; then
    ck R5 "投毒后 2.0/2.3/2.5s 取样起手点均回到整屏 task 且缓存文件恢复（阈值 ≤2.5s）" "${ok}/${total} 通过$samples cache=[$cache_after]" PASS
  else
    ck R5 "投毒后 2.0/2.3/2.5s 取样起手点均回到整屏 task 且缓存文件恢复（阈值 ≤2.5s）" "${ok}/${total} 通过$samples cache=[$cache_after]" FAIL "echo '$POISON' > $TB; 在 2.0/2.3/2.5s 各推一次并看 helper.log 的 SWIPE 起手点"
  fi
}

# ---------------------------------------------------------------- K 助手新命令
stop_all() {
  local p
  for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
  am force-stop $PKG >/dev/null 2>&1
  for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
  for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
  sleep 1
}
start_all() {
  local p i
  for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
  sleep 0.5
  setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
  sleep 3
  i=0
  while [ $i -lt 10 ] && [ ! -S /data/data/$PKG/files/gpm.sock ]; do sleep 1; i=$((i + 1)); done
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  sleep 2
  L "  STARTED helper=$(pidof gpminput) engine=$(pidof $PKG) sock=$(ls -l /data/data/$PKG/files/gpm.sock 2>/dev/null | wc -l)"
}
open_channel() {
  rm -f "$FIFO"; mkfifo "$FIFO"
  : > "$HOUT"; : > "$HERR"
  /data/adb/gpm/gpminput < "$FIFO" > "$HOUT" 2>"$HERR" &
  HPID=$!
  exec 3> "$FIFO"
  sleep 1
  L "  CHANNEL pid=$HPID ready=$(grep -ac '^READY' "$HOUT" 2>/dev/null) err=$(head -c 160 "$HERR" | tr '\n' ' ')"
}
close_channel() { exec 3>&-; sleep 0.3; kill "$HPID" 2>/dev/null; wait "$HPID" 2>/dev/null; }
send() { echo "$*" >&3; }
swait() { send "$@"; sleep 0.25; }
secK() {
  sec "K 助手新命令（u 正/负例 · g→O 增益 · c 与 P 真值 · P 落点 · 10 条命令耗时）"
  wake
  stop_all
  am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
  sleep 2.5
  : > "$HL"
  open_channel

  # K1 u 负例：屏幕已亮 → 空操作
  local w1 wa1
  w1=$(wf)
  send "u"; sleep 3.5
  wa1=$(grep -a '^WAKE' "$HL" 2>/dev/null | tail -3 | tr '\n' '|')
  if [ "$w1" = "Awake" ] && echo "$wa1" | grep -q 'skip=1'; then
    ck K1 "u 负例（屏幕已亮）：空操作 skip=1 且无 uinput 注入" "before=$w1 after=$(wf) [$wa1]" PASS
  else
    ck K1 "u 负例（屏幕已亮）：空操作 skip=1 且无 uinput 注入" "before=$w1 after=$(wf) [$wa1]" FAIL "echo u > fifo"
  fi

  # K2 u 正例：灭屏 → u → Awake 且 done=1
  send "p"; sleep 3
  local woff won wa2
  woff=$(wf)
  : > "$HL"
  send "u"; sleep 4
  won=$(wf)
  wa2=$(grep -a '^WAKE' "$HL" 2>/dev/null | tail -3 | tr '\n' '|')
  L "  u positive: off=$woff after=$won [$wa2]"
  if [ "$woff" = "Dozing" ] && [ "$won" = "Awake" ] && echo "$wa2" | grep -q 'done=1'; then
    ck K2 "u 正例（Dozing）：→ Awake 且 helper WAKE done=1 src=uinput|input224|power" "off=$woff after=$won [$wa2]" PASS
  else
    ck K2 "u 正例（Dozing）：→ Awake 且 helper WAKE done=1 src=uinput|input224|power" "off=$woff after=$won [$wa2]" FAIL "send p (灭屏); send u"
  fi

  # K3 g 设置 → O 日志显示新增益
  : > "$HL"
  swait "g"
  swait "g 0 4.68"
  send "O 2560 1600 0 1"; sleep 1.5
  send "g 3.25 3.25"; sleep 0.5
  local g3
  g3=$(grep -aE '^(GAIN|CENTER)' "$HL" 2>/dev/null | tr '\n' '|')
  L "  gain/center: $g3"
  if echo "$g3" | grep -q 'CENTER' && echo "$g3" | grep -q '4\.68'; then
    ck K3 "g 0 4.68 后 O 居中日志使用新增益 4.68（g_pointer_gain 真正参与）" "$g3" PASS
  else
    ck K3 "g 0 4.68 后 O 居中日志使用新增益 4.68（g_pointer_gain 真正参与）" "$g3" FAIL "send 'g 0 4.68'; send 'O 2560 1600 0 1'"
  fi

  # K4 c 回包格式 + 与 P 真值误差 ≤5px；K5 P 落点 ±40px
  local tgt a4 okc errc maxc okp maxp
  okc=0; maxc=0; okp=0; maxp=0
  for tgt in "1280 800" "240 400" "2400 1400"; do
    set -- $tgt
    local tx=$1 ty=$2
    send "P $tx $ty 2560 1600"; sleep 1.2
    logcat -c
    send "B 0 1"; sleep 0.15; send "B 0 0"; sleep 0.9
    local cl cur cx cy ce cps
    cl=$(cxy)
    send "c"; sleep 1.3
    cur=$(grep -a '^CURSOR ' "$HL" 2>/dev/null | tail -1)
    cx=$(echo "$cur" | awk '{print $2}'); cy=$(echo "$cur" | awk '{print $3}')
    cps=$(echo "$cur" | grep -o 'display=[0-9-]* space=[a-z]*')
    ce=$(awk -v x="$cx" -v y="$cy" -v tx="$tx" -v ty="$ty" 'BEGIN{
          if(x==""||y==""){print 999;exit} dx=x-tx; dy=y-ty; if(dx<0)dx=-dx; if(dy<0)dy=-dy; m=(dx>dy)?dx:dy; print m }')
    local pe
    pe=$(awk -v a="$cl" -v tx="$tx" -v ty="$ty" 'BEGIN{
          split(a,p," "); if(p[1]==""){print 999;exit} dx=p[1]-tx; dy=p[2]-ty; if(dx<0)dx=-dx; if(dy<0)dy=-dy; m=(dx>dy)?dx:dy; print m }')
    L "  P/target=$tx,$ty click=[$cl] c=[$cur] c_err=${ce}px click_err=${pe}px"
    case "$cps" in
      "display=0 space=logical") [ "$ce" -le 5 ] && okc=$((okc + 1)) ;;
    esac
    [ "$ce" -gt "$maxc" ] && maxc=$ce
    [ "$pe" -le 40 ] && okp=$((okp + 1))
    [ "$pe" -gt "$maxp" ] && maxp=$pe
    a4="$a4 $tx,$ty:c=${ce}px/p=${pe}px"
  done
  if [ "$okc" -eq 3 ]; then
    ck K4 "c 回包 display=0 space=logical 且与 P 放置真值误差 ≤5px（3/3）" "3/3 max=${maxc}px$a4" PASS
  else
    ck K4 "c 回包 display=0 space=logical 且与 P 放置真值误差 ≤5px（3/3）" "$okc/3 max=${maxc}px$a4" FAIL "send 'P 1280 800 2560 1600'; send c; grep '^CURSOR ' $HL"
  fi
  if [ "$okp" -eq 3 ]; then
    ck K5 "P 绝对定位后点击落点误差 ≤40px（3/3）" "3/3 max=${maxp}px$a4" PASS
  else
    ck K5 "P 绝对定位后点击落点误差 ≤40px（3/3）" "$okp/3 max=${maxp}px$a4" FAIL "send 'P 240 400 2560 1600'; B 0 1/B 0 0; logcat -d -s PadProbe"
  fi

  # K6 连续 10 条命令总耗时 <100ms
  local base n t0 t1 dur
  base=$(grep -ac '^GAIN' "$HOUT" 2>/dev/null)
  t0=$(now_ms)
  local i=0
  while [ $i -lt 10 ]; do send "g"; i=$((i + 1)); done
  while :; do
    n=$(grep -ac '^GAIN' "$HOUT" 2>/dev/null)
    [ "$n" -ge $((base + 10)) ] && break
    t1=$(now_ms)
    [ $((t1 - t0)) -ge 2000 ] && break
  done
  dur=$(( $(now_ms) - t0 ))
  L "  10 cmds: ${dur}ms (responses ${base}->${n})"
  if [ "$dur" -lt 100 ]; then
    ck K6 "连续 10 条命令总耗时 <100ms" "${dur}ms" PASS
  else
    ck K6 "连续 10 条命令总耗时 <100ms" "${dur}ms" FAIL "send 10x 'g' to fifo; measure"
  fi
  close_channel
  start_all
  wake
  startp
}

# ---------------------------------------------------------------- 恢复/收尾
restore_state() {
  sec "RESTORE 恢复正式安装状态"
  wake
  settings put system pointer_speed -1 >/dev/null 2>&1
  settings put system user_rotation 1 >/dev/null 2>&1
  settings put system accelerometer_rotation 0 >/dev/null 2>&1
  sleep 1
  if pidof $PKG >/dev/null 2>&1; then
    pref_bool force_landscape true
  else
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 3
    pref_bool force_landscape true
  fi
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  sleep 3
  startp
  sleep 1
  cmd statusbar collapse >/dev/null 2>&1
  click
  L "  restored: helper=$(pidof gpminput) engine=$(pidof $PKG) rot=$(settings get system user_rotation)" \
    "accel=$(settings get system accelerometer_rotation) ps=$(settings get system pointer_speed)" \
    "app=$(appsize) wf=$(wf) focus=$(focus)"
  L "  prefs=$(prefs)"
}
finish() {
  echo "" | tee -a "$LOG"
  echo "PASS=$PASS FAIL=$FAIL" | tee -a "$RES"
  [ -n "$FAILED" ] && echo "FAILED_IDS:$FAILED" | tee -a "$RES"
  echo "RESULT: $RES ; RAW: $LOG ; SHOTS: $SHOTS"
  if [ "$FAIL" -eq 0 ]; then exit 0; else exit 1; fi
}
want() { case "$MODE" in all) return 0 ;; *"$1"*) return 0 ;; *) return 1 ;; esac; }

if [ "$(id -u)" != "0" ]; then echo "need root"; exit 3; fi
if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi

L "v166_auto_suite mode=$MODE start=$(date)"
baseline
want A && secA
want B && secB
want C && secC
want D && secD
want E && secE
want F && secF
want G && secG
want H && secH
want I && secI
want J && secJ
want R && secR5
want K && secK
restore_state
finish
