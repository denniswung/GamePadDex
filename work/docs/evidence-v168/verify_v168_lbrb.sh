#!/system/bin/sh
# verify_v168_lbrb.sh -- v1.68 release 字节（c8b00288）实测 LB/RB 连续拖拽
#
# 覆盖验收项：
#   · 短按 100ms 位移 ≤150px
#   · 按住 1.5s 位移 1200–2200px
#   · 触屏模式 SWIPE=0 / WHEEL=0（纯 d/m/e 拖拽，不是离散 swipe）
#   · 滚轮模式 1.5s WHEEL=9 / SWIPE=0
#   · PiliPlus 前台 1.5s：截图 before/after（PC 侧算差异，脚本只负责采集 + 引擎 total）
#
# release 包 debuggable=false，DEBUG/HCMD 广播被忽略 → 滚轮开关用 prefs XML + 重启引擎。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
OUT=/data/local/tmp/verify_v168_lbrb.result
SHOTS=/data/local/tmp/v168_shots
EXPECT_APK="${EXPECT_APK:-c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998}"
EXPECT_HELPER="${EXPECT_HELPER:-a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d}"
PASS=0; FAIL=0; FAILED=""
mkdir -p "$SHOTS" 2>/dev/null; rm -f "$SHOTS"/*.png 2>/dev/null; : > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
prefs_path(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
vt(){ grep -o 'v_touch_scroll" value="[a-z]*"' "$(prefs_path)" 2>/dev/null | sed 's/.*value="//;s/"//'; }
set_vt(){ # sed 先行 -> force-stop -> start：避免模块 watchdog 在 sed 之前拉起引擎、进程缓存旧值
  sed -i "s/v_touch_scroll\" value=\"[a-z]*\"/v_touch_scroll\" value=\"$1\"/" "$(prefs_path)" 2>/dev/null
  am force-stop $PKG >/dev/null 2>&1; sleep 1.2
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0; while [ $i -lt 25 ]; do i=$((i+1)); sleep 0.6; pidof $PKG >/dev/null 2>&1 && [ "$(vt)" = "$1" ] && { sleep 2.5; return 0; }; done; return 1; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
drag_end(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/^.*drag end total=//'; }
drag_total(){ drag_end | sed 's/px.*//'; }
drag_dur(){ drag_end | sed 's/.*dur=//;s/ms.*//'; }
drag_start(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag start ' | tail -1 | sed 's/^.*drag start //'; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
modes(){ logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | sed 's/^.*DexPad *: //' | tail -2 | tr '\n' '|'; }

# ---------------------------------------------------------------- 0 基线
sec "0 基线（v1.68 release 字节）"
wake; pin
APKH=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
HELH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
VER=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//'); VC=$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
MODPROP=$(grep -E '^(version|versionCode)=' /data/adb/modules/gpm_dex/module.prop | tr '\n' ' ')
L "  apk=$APKH"; L "  helper=$HELH module=$MODH"; L "  version=$VER/$VC module.prop=$MODPROP"
[ "$APKH" = "$EXPECT_APK" ] && ck V168-APK "设备 base.apk == 发布 dexpad-v1.68.apk" "$APKH" PASS || ck V168-APK "设备 base.apk == 发布 dexpad-v1.68.apk" "$APKH" FAIL "pm path"
{ [ "$HELH" = "$EXPECT_HELPER" ] && [ "$MODH" = "$EXPECT_HELPER" ]; } && ck V168-HELPER "助手 gpm==模块==发布哈希" "$HELH / $MODH" PASS || ck V168-HELPER "助手 gpm==模块==发布哈希" "$HELH / $MODH" FAIL "sha256sum"
{ [ "$VER" = "1.68" ] && [ "$VC" = "70" ] && echo "$MODPROP" | grep -q 'v1.68'; } && ck V168-VER "versionName=1.68 / versionCode=70（module.prop v1.68/70）" "$VER/$VC | $MODPROP" PASS || ck V168-VER "versionName=1.68 / versionCode=70" "$VER/$VC | $MODPROP" FAIL "dumpsys"
ASZ=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
ROT=$(settings get system user_rotation); ACC=$(settings get system accelerometer_rotation)
{ [ "$ROT" = "1" ] && [ "$ACC" = "0" ] && [ "$ASZ" = "2560x1600" ]; } && ck V168-LAND "默认横屏 user_rotation=1 accel=0 app=2560x1600" "rot=$ROT accel=$ACC app=$ASZ" PASS || ck V168-LAND "默认横屏" "rot=$ROT accel=$ACC app=$ASZ" FAIL

# ---------------------------------------------------------------- A 触屏拖拽：短按/300ms/1.5s
sec "A 触屏模式（v_touch_scroll=true）：LB/RB = 连续拖拽（d/m/e）"
set_vt true >/dev/null 2>&1
L "  vtouch=$(vt)"
# A1 短按 100ms（RB）
starts; : > "$HL"; logcat -c
$VG key 311 100 400 >/dev/null 2>&1; sleep 0.7
T100=$(drag_total); D100=$(drag_dur); S100=$(swipe_n); W100=$(wheel_n); ST=$(drag_start)
L "  100ms: total=${T100}px dur=${D100}ms SWIPE=$S100 WHEEL=$W100 start=[$ST]"
if [ -n "$T100" ] && [ "$T100" -le 150 ] && [ "$T100" -gt 0 ]; then ck V168-SHORT "RB 短按 100ms 位移 0<t≤150px" "total=${T100}px (dur=${D100}ms)" PASS
else ck V168-SHORT "RB 短按 100ms 位移 0<t≤150px" "total=${T100:-none}px" FAIL "vgpad key 311 100 400; logcat -d -s DexPad | grep 'drag end'"; fi
{ [ "$S100" -eq 0 ] && [ "$W100" -eq 0 ]; } && ck V168-NOSWIPE "触屏拖拽期间 SWIPE=0 且 WHEEL=0（纯 d/m/e）" "SWIPE=$S100 WHEEL=$W100" PASS || ck V168-NOSWIPE "触屏拖拽期间 SWIPE=0 且 WHEEL=0" "SWIPE=$S100 WHEEL=$W100" FAIL "grep '^SWIPE |^WHEEL' helper.log"
# A2 300ms
starts; logcat -c
$VG key 311 300 400 >/dev/null 2>&1; sleep 0.8
T300=$(drag_total); D300=$(drag_dur)
L "  300ms: total=${T300}px dur=${D300}ms"
if [ -n "$T300" ] && [ "$T300" -le 450 ] && [ "$T300" -gt "$T100" ]; then ck V168-300MS "RB 300ms 位移 ≤450px 且 >100ms 位移（单调）" "total=${T300}px (100ms=${T100}px)" PASS
else ck V168-300MS "RB 300ms 位移 ≤450px 且单调" "total=${T300:-none}px (100ms=${T100:-?})" FAIL "vgpad key 311 300 400"; fi
# A3 1.5s（页顶起手，重置页面）
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.0
T1500=$(drag_total); D1500=$(drag_dur); S1500=$(swipe_n); W1500=$(wheel_n); ST1500=$(drag_start)
L "  1500ms: total=${T1500}px dur=${D1500}ms SWIPE=$S1500 WHEEL=$W1500 start=[$ST1500]"
if [ -n "$T1500" ] && [ "$T1500" -ge 1200 ] && [ "$T1500" -le 2200 ]; then ck V168-1500 "RB 按住 1.5s 位移 ∈[1200,2200]px" "total=${T1500}px (dur=${D1500}ms)" PASS
else ck V168-1500 "RB 按住 1.5s 位移 ∈[1200,2200]px" "total=${T1500:-none}px" FAIL "vgpad key 311 1500 400"; fi
{ [ "$S1500" -eq 0 ] && [ "$W1500" -eq 0 ]; } && ck V168-1500-PURE "1.5s 拖拽期间仍 SWIPE=0/WHEEL=0" "SWIPE=$S1500 WHEEL=$W1500" PASS || ck V168-1500-PURE "1.5s 拖拽期间仍 SWIPE=0/WHEEL=0" "SWIPE=$S1500 WHEEL=$W1500" FAIL "grep helper.log"
case "$ST1500" in *mult=1.0*) ck V168-MULT "默认 scroll_speed=4 → mult=1.0（速度可调基准）" "$ST1500" PASS ;; *) ck V168-MULT "默认 scroll_speed=4 → mult=1.0" "${ST1500:-none}" FAIL "logcat drag start" ;; esac
# A4 位移落到内容（uiautomator：RB 从页顶，PY 应显著减少）
starts
ui(){ timeout 12 uiautomator dump /sdcard/v168.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v168.xml > /sdcard/v168.lines 2>/dev/null; }
PY=-1
pyscan(){ PY=-1; local n l b y1
  for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v168.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; y1=$2; [ "$PY" = "-1" ] && PY=$y1; done; }
PY0=-1; t=0
while [ $t -lt 3 ]; do t=$((t+1)); ui; pyscan; [ "$PY" != "-1" ] && { PY0=$PY; break; }; sleep 1.0; done
L "  PY0=$PY0 (dump tries=$t)"
logcat -c; $VG key 311 1500 400 >/dev/null 2>&1; sleep 1.4
PY1=-1; t=0
while [ $t -lt 3 ]; do t=$((t+1)); ui; pyscan; [ "$PY" != "-1" ] && { PY1=$PY; break; }; sleep 1.0; done
DPY=$((PY0 - PY1)); [ "$DPY" -lt 0 ] && DPY=$((-DPY))
L "  content: PY $PY0 -> $PY1 d=$DPY (engine total=$(drag_total)px)"
[ "$PY0" != "-1" ] && [ "$PY1" != "-1" ] && [ "$DPY" -ge 600 ] && ck V168-MOVE "RB 1.5s 内容实际位移 ≥600px（padtest 页顶起手）" "PY $PY0->$PY1 d=$DPY" PASS || ck V168-MOVE "RB 1.5s 内容实际位移 ≥600px" "PY $PY0->$PY1 d=$DPY" FAIL "uiautomator dump (retry x3)"

# ---------------------------------------------------------------- B 滚轮模式
sec "B 滚轮模式（v_touch_scroll=false）：LB/RB 只出滚轮"
if set_vt false; then ck V168-VT-OFF "release 包上 v_touch_scroll=false 生效（prefs+重启引擎）" "vtouch=$(vt) engine=$(pidof $PKG)" PASS
else ck V168-VT-OFF "release 包上 v_touch_scroll=false 生效" "vtouch=$(vt)" FAIL "sed prefs"; fi
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.2
W=$(wheel_n); S=$(swipe_n); MD=$(modes); DT=$(drag_total)
L "  wheel RB 1.5s: WHEEL=$W SWIPE=$S drag=[$DT] mode=[$MD]"
{ [ "$W" -ge 6 ] && [ "$S" -eq 0 ] && echo "$MD" | grep -q 'mode=wheel'; } && ck V168-WHEEL-RB "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0 且 mode=wheel" "WHEEL=$W SWIPE=$S | $MD" PASS || ck V168-WHEEL-RB "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W SWIPE=$S | $MD" FAIL "vgpad key 311 1500"
: > "$HL"; logcat -c
$VG key 310 1500 400 >/dev/null 2>&1; sleep 1.2
W2=$(wheel_n); S2=$(swipe_n); MD2=$(modes)
L "  wheel LB 1.5s: WHEEL=$W2 SWIPE=$S2 mode=[$MD2]"
{ [ "$W2" -ge 6 ] && [ "$S2" -eq 0 ] && echo "$MD2" | grep -q 'mode=wheel'; } && ck V168-WHEEL-LB "滚轮 LB 1.5s：WHEEL≥6 且 SWIPE=0 且 mode=wheel" "WHEEL=$W2 SWIPE=$S2 | $MD2" PASS || ck V168-WHEEL-LB "滚轮 LB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W2 SWIPE=$S2 | $MD2" FAIL "vgpad key 310 1500"
set_vt true >/dev/null 2>&1
ck V168-RESTORE "恢复 v_touch_scroll=true（默认安装态）" "vtouch=$(vt) engine=$(pidof $PKG)" "$([ "$(vt)" = "true" ] && echo PASS || echo FAIL)" "sed prefs"

# ---------------------------------------------------------------- C PiliPlus 1.5s 前后截图
sec "C PiliPlus 前台 RB 1.5s：前后截图 + 引擎总位移"
am force-stop com.example.piliplus >/dev/null 2>&1
am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 5.0
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
L "  top=$TOP"
screencap -p "$SHOTS/pili_before.png" >/dev/null 2>&1
logcat -c
$VG key 311 1500 400 >/dev/null 2>&1
sleep 1.2
screencap -p "$SHOTS/pili_after.png" >/dev/null 2>&1
PT=$(drag_total); PD=$(drag_dur)
L "  pili drag: total=${PT}px dur=${PD}ms"
case "$TOP" in *piliplus*) ck V168-PILI-TOP "PiliPlus 在前台（截图对象正确）" "top=$TOP" PASS ;; *) ck V168-PILI-TOP "PiliPlus 在前台" "top=$TOP" FAIL "am start -n com.example.piliplus/.MainActivity" ;; esac
if [ -n "$PT" ] && [ "$PT" -ge 1200 ] && [ "$PT" -le 2200 ]; then ck V168-PILI-TOTAL "PiliPlus 1.5s 引擎总位移 ∈[1200,2200]px（≈2200 封顶）" "total=${PT}px (dur=${PD}ms)" PASS
else ck V168-PILI-TOTAL "PiliPlus 1.5s 引擎总位移 ∈[1200,2200]px" "total=${PT:-none}px" FAIL "vgpad key 311 1500 (PiliPlus)"; fi
# 三图渐进（三次 500ms，段间截图为新鲜帧）
am force-stop com.example.piliplus >/dev/null 2>&1; am start -n com.example.piliplus/.MainActivity >/dev/null 2>&1; sleep 5.0
screencap -p "$SHOTS/prog0.png" >/dev/null 2>&1
logcat -c
$VG key 311 500 400 >/dev/null 2>&1; sleep 0.9; screencap -p "$SHOTS/prog1.png" >/dev/null 2>&1
$VG key 311 500 400 >/dev/null 2>&1; sleep 0.9; screencap -p "$SHOTS/prog2.png" >/dev/null 2>&1
$VG key 311 500 400 >/dev/null 2>&1; sleep 0.9; screencap -p "$SHOTS/prog3.png" >/dev/null 2>&1
L "  progressive totals: $(logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -3 | sed 's/^.*total=//;s/px.*//' | tr '\n' '/')"
for f in pili_before pili_after prog0 prog1 prog2 prog3; do
  sz=$(stat -c %s "$SHOTS/$f.png" 2>/dev/null); L "  shot $f.png = ${sz:-missing}B"
done

# ---------------------------------------------------------------- restore
sec "RESTORE"
am force-stop com.example.piliplus >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5
L "  restored: helper=$(pidof gpminput) engine=$(pidof $PKG) vtouch=$(vt) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) app=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)"
L ""
L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
