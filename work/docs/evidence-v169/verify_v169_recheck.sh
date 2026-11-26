#!/system/bin/sh
# verify_v169_recheck.sh -- v1.69 发布字节：RS3-V / RS4-HIDDEN 用「外层锚点」重测
#
# 背景：padtest v1.4（t60）让内层 vList 在 ACTION_DOWN 时 requestDisallowInterceptTouchEvent，
# 因此右摇杆竖推若锚点落在内层列表上，外层 "第 1 页" 的 PY 不变（内层滚动），旧判据读不到位移。
# 本脚本先用 root 控制通道 P 把指针放到外层区域（1280,300），再推；同时导出 padtest v1.4 report 记录
# instrumentation.scroll.vertical_offset，作为内层/整体滚动的旁证。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
SOCK=/data/adb/gpm/gpmctl.sock
CTL=/data/local/tmp/gpmctl
OUT=/data/local/tmp/verify_v169_recheck.result
PASS=0; FAIL=0; FAILED=""
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.6; cmd statusbar collapse >/dev/null 2>&1; sleep 0.5; }
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
PY=-1
ui(){ timeout 12 uiautomator dump /sdcard/v169r.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v169r.xml > /sdcard/v169r.lines 2>/dev/null; }
pyscan(){ PY=-1; local n l b y1
  for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v169r.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; y1=$2; [ "$PY" = "-1" ] && PY=$y1; done; }
dumpPY(){ local t=0; while [ $t -lt 4 ]; do t=$((t+1)); ui; pyscan; [ "$PY" != "-1" ] && return 0; sleep 0.8; done; return 1; }
voff(){ local f=/data/local/tmp/v169r_report.json
  am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
  sleep 1.0
  local p=$(ls /sdcard/Android/data/com.dennis.padtest/files/auto-report-latest.json 2>/dev/null | head -1)
  [ -n "$p" ] && grep -o '"vertical_offset": *[0-9-]*' "$p" | head -1 | sed 's/.*: *//'
}

sec "RS3-V 竖推（外层锚点 1280,300）"
wake; pin
starts
ctl j >/dev/null 2>&1; sleep 0.7
ctl P 1280 300 2560 1600 >/dev/null 2>&1; sleep 0.8
dumpPY; PY0=$PY; V0=$(voff)
: > "$HL"; logcat -c
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.4
dumpPY; PY1=$PY; V1=$(voff)
Z=$(grep -ac '^SWIPE .* axis=Z ' "$HL" 2>/dev/null)
V=$(grep -ac '^SWIPE .* axis=V ' "$HL" 2>/dev/null)
DPY=$((PY0 - PY1)); [ "$DPY" -lt 0 ] && DPY=$((-DPY))
L "  anchor=(1280,300) PY $PY0 -> $PY1 d=$DPY Z=$Z V=$V vertical_offset $V0 -> $V1"
{ [ "$PY0" != "-1" ] && [ "$PY1" != "-1" ] && [ "$DPY" -ge 200 ] && [ "$Z" -ge 1 ] && [ "$V" -eq 0 ]; } \
  && ck RS3V-OUTER-ANCHOR "外层锚点竖推 1.5s：外层内容位移 ≥200px 且 helper 仅 Z" "PY $PY0->$PY1 d=$DPY Z=$Z V=$V voff $V0->$V1" PASS \
  || ck RS3V-OUTER-ANCHOR "外层锚点竖推 1.5s：外层内容位移 ≥200px 且 helper 仅 Z" "PY $PY0->$PY1 d=$DPY Z=$Z V=$V voff $V0->$V1" FAIL "P 1280 300; stick 4 24000 1500"

sec "RS4-HIDDEN 空闲隐藏后首次竖推（外层锚点）"
starts
ctl j >/dev/null 2>&1; sleep 0.7
ctl P 1280 300 2560 1600 >/dev/null 2>&1; sleep 0.8
dumpPY; PY0=$PY
POFF0=$(grep -ac 'POINTER off' "$HL" 2>/dev/null)
sleep 9.5
POFF1=$(grep -ac 'POINTER off' "$HL" 2>/dev/null)
PTR=$(getevent -pl 2>/dev/null | grep -c 'Gamepad Mouse Pointer')
: > "$HL"; logcat -c
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.4
dumpPY; PY1=$PY
Z=$(grep -ac '^SWIPE .* axis=Z ' "$HL" 2>/dev/null)
DPY=$((PY0 - PY1)); [ "$DPY" -lt 0 ] && DPY=$((-DPY))
L "  POINTER off $POFF0->$POFF1 ptr_dev=$PTR PY $PY0 -> $PY1 d=$DPY Z=$Z"
{ [ "$POFF1" -gt "$POFF0" ] && [ "$PTR" -eq 0 ] && [ "$PY1" != "-1" ] && [ "$DPY" -ge 200 ] && [ "$Z" -ge 1 ]; } \
  && ck RS4-HIDDEN-OUTER "隐藏后首次竖推：外层内容位移 ≥200px（Z≥1）" "POFF $POFF0->$POFF1 ptr=$PTR dPY=$DPY Z=$Z" PASS \
  || ck RS4-HIDDEN-OUTER "隐藏后首次竖推：外层内容位移 ≥200px（Z≥1）" "POFF $POFF0->$POFF1 ptr=$PTR dPY=$DPY Z=$Z" FAIL "P 1280 300; sleep 9.5; stick 4 24000 1500"

sec "RESTORE"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.2
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
L ""; L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
