#!/system/bin/sh
# verify_v168_lbrb_b.sh -- v1.68 release 字节：B 滚轮模式（修正版）+ A4 内容位移（停引擎 dump）
#
# 与 verify_v168_lbrb.sh 的区别：
#  1) set_vt 顺序改为「先 sed 再 force-stop 再 start」，避免模块 watchdog 在 sed 前拉起引擎、
#     进程缓存旧值导致改了 prefs 仍走 swipe（v1 首跑 V168-WHEEL-RB/LB FAIL 的根因）。
#  2) 内容位移用「停引擎 → uiautomator dump → 重启引擎」：padtest 上有 overlay 时 dump 拿不到节点。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
OUT=/data/local/tmp/verify_v168_lbrb_b.result
PASS=0; FAIL=0; FAILED=""
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
ppath(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
vt(){ grep -o 'v_touch_scroll" value="[a-z]*"' "$(ppath)" 2>/dev/null | sed 's/.*value="//;s/"//'; }
set_vt(){ # sed 先行 -> force-stop -> start（避免 watchdog 抢跑缓存旧值）
  sed -i "s/v_touch_scroll\" value=\"[a-z]*\"/v_touch_scroll\" value=\"$1\"/" "$(ppath)" 2>/dev/null
  am force-stop $PKG >/dev/null 2>&1; sleep 1.2
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0; while [ $i -lt 25 ]; do i=$((i+1)); sleep 0.6; pidof $PKG >/dev/null 2>&1 && [ "$(vt)" = "$1" ] && { sleep 2.5; return 0; }; done; return 1; }
engine_stop(){ am force-stop $PKG >/dev/null 2>&1; sleep 1.2; }
engine_start(){ am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 3.0; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
modes(){ logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | sed 's/^.*DexPad *: //' | tail -2 | tr '\n' '|'; }
drag_total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/^.*total=//;s/px.*//'; }
PY=-1
ui(){ timeout 12 uiautomator dump /sdcard/v168b.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v168b.xml > /sdcard/v168b.lines 2>/dev/null; }
pyscan(){ PY=-1; local n l b y1
  for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v168b.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; [ "$PY" = "-1" ] && PY=$y1; done; }

sec "B2 滚轮模式（v_touch_scroll=false，sed 先行 + 强制重启引擎）"
wake; pin
L "  before: vtouch=$(vt) pid=$(pidof $PKG)"
if set_vt false; then ck V168B-VT-OFF "release 包上 v_touch_scroll=false 生效（无调试广播）" "vtouch=$(vt) engine=$(pidof $PKG)" PASS
else ck V168B-VT-OFF "release 包上 v_touch_scroll=false 生效" "vtouch=$(vt) engine=$(pidof $PKG)" FAIL "sed prefs + force-stop + start"; fi
sleep 1.0
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.4
W=$(wheel_n); S=$(swipe_n); MD=$(modes); DT=$(drag_total)
L "  RB 1.5s: WHEEL=$W SWIPE=$S drag=[$DT] mode=[$MD]"
{ [ "$W" -ge 6 ] && [ "$S" -eq 0 ] && echo "$MD" | grep -q 'mode=wheel'; } && ck V168B-WHEEL-RB "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0 且 mode=wheel" "WHEEL=$W SWIPE=$S | $MD" PASS || ck V168B-WHEEL-RB "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W SWIPE=$S | $MD" FAIL "vgpad key 311 1500 (vt=false)"
: > "$HL"; logcat -c
$VG key 310 1500 400 >/dev/null 2>&1; sleep 1.4
W2=$(wheel_n); S2=$(swipe_n); MD2=$(modes); DT2=$(drag_total)
L "  LB 1.5s: WHEEL=$W2 SWIPE=$S2 drag=[$DT2] mode=[$MD2]"
{ [ "$W2" -ge 6 ] && [ "$S2" -eq 0 ] && echo "$MD2" | grep -q 'mode=wheel'; } && ck V168B-WHEEL-LB "滚轮 LB 1.5s：WHEEL≥6 且 SWIPE=0 且 mode=wheel" "WHEEL=$W2 SWIPE=$S2 | $MD2" PASS || ck V168B-WHEEL-LB "滚轮 LB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W2 SWIPE=$S2 | $MD2" FAIL "vgpad key 310 1500 (vt=false)"

sec "A4b 触屏模式内容位移（停引擎 dump）"
if set_vt true; then L "  restored vtouch=$(vt)"; else L "  restore failed vtouch=$(vt)"; fi
starts
engine_stop; ui; pyscan; PY0=$PY; L "  PY0=$PY0 (engine stopped dump)"; engine_start
logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.2
T=$(drag_total)
engine_stop; ui; pyscan; PY1=$PY; engine_start
DPY=$((PY0 - PY1)); [ "$DPY" -lt 0 ] && DPY=$((-DPY))
L "  PY $PY0 -> $PY1 d=$DPY engine_total=${T}px"
if [ "$PY0" != "-1" ] && [ "$PY1" != "-1" ] && [ "$DPY" -ge 600 ]; then ck V168B-MOVE "RB 1.5s 内容实际位移 ≥600px（停引擎 dump）" "PY $PY0->$PY1 d=$DPY total=${T}px" PASS
else ck V168B-MOVE "RB 1.5s 内容实际位移 ≥600px" "PY $PY0->$PY1 d=$DPY total=${T}px" FAIL "uiautomator dump with engine stopped"; fi

sec "RESTORE"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.5
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) vtouch=$(vt) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) app=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)"
L ""; L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
