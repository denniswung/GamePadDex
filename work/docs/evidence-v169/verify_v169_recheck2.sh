#!/system/bin/sh
# verify_v169_recheck2.sh -- v1.69 发布字节：右摇杆竖推 / 隐藏后首推，用 padtest v1.4 权威字段判定
#
# padtest v1.4（t60）在 ACTION_DOWN 时让内层 vList requestDisallowInterceptTouchEvent(true)，
# 所以锚点落在内层时**内层列表滚动、外层标题不动** —— v1.68 时期"读外层 PY"的判据在 v1.4 上失效。
# 本脚本按 v1.4 的权威字段判定：
#   · instrumentation.scroll.vertical_offset（内层列表滚动量）
#   · instrumentation.touch.path_px / frames（注入手势本身）
#   · helper.log 的 SWIPE axis=Z 计数
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
SOCK=/data/adb/gpm/gpmctl.sock
CTL=/data/local/tmp/gpmctl
OUT=/data/local/tmp/verify_v169_recheck2.result
PASS=0; FAIL=0; FAILED=""
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.6; cmd statusbar collapse >/dev/null 2>&1; sleep 0.5; }
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
export_json(){ am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
  sleep 1.2; logcat -d | grep -a 'EXPORT what=report' | tail -1 | sed 's/.*path=//;s/ size=.*//'; }
field(){ grep -o "\"$2\": *[0-9-]*" "$1" 2>/dev/null | head -1 | sed 's/.*: *//'; }
voff(){ local f=$(export_json); [ -z "$f" ] && { echo ""; return; }; field "$f" vertical_offset; }
tpath(){ local f=$(export_json); [ -z "$f" ] && { echo ""; return; }; field "$f" path_px; }

sec "R1 右摇杆竖推（锚点 1280,1000 内层 vList）→ instrumentation.vertical_offset"
wake; pin
starts
ctl j >/dev/null 2>&1; sleep 0.7
ctl P 1280 1000 2560 1600 >/dev/null 2>&1; sleep 0.8
V0=$(voff); P0=$(tpath)
: > "$HL"; logcat -c
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.4
V1=$(voff); P1=$(tpath); Z=$(grep -ac '^SWIPE .* axis=Z ' "$HL" 2>/dev/null)
L "  vertical_offset $V0 -> $V1 | touch.path_px $P0 -> $P1 | Z=$Z"
{ [ -n "$V1" ] && [ -n "$V0" ] && [ "$V1" -gt "$V0" ] && [ "$Z" -ge 1 ]; } \
  && ck R1-VOFF "竖推 1.5s：内层 vertical_offset 增加 且 helper Z≥1" "voff $V0->$V1 Z=$Z path $P0->$P1" PASS \
  || ck R1-VOFF "竖推 1.5s：内层 vertical_offset 增加 且 helper Z≥1" "voff $V0->$V1 Z=$Z path $P0->$P1" FAIL "P 1280 1000; stick 4 24000 1500"

sec "R2 空闲隐藏后首次竖推（锚点 1280,1000）"
starts
ctl j >/dev/null 2>&1; sleep 0.7
ctl P 1280 1000 2560 1600 >/dev/null 2>&1; sleep 0.8
V0=$(voff)
POFF0=$(grep -ac 'POINTER off' "$HL" 2>/dev/null)
sleep 9.5
POFF1=$(grep -ac 'POINTER off' "$HL" 2>/dev/null)
PTR=$(getevent -pl 2>/dev/null | grep -c 'Gamepad Mouse Pointer')
: > "$HL"; logcat -c
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.4
V1=$(voff); Z=$(grep -ac '^SWIPE .* axis=Z ' "$HL" 2>/dev/null)
L "  POINTER off $POFF0->$POFF1 ptr_dev=$PTR vertical_offset $V0 -> $V1 Z=$Z"
{ [ "$PTR" -eq 0 ] && [ -n "$V1" ] && [ -n "$V0" ] && [ "$V1" -gt "$V0" ] && [ "$Z" -ge 1 ]; } \
  && ck R2-HIDDEN "隐藏后首次竖推：内层 vertical_offset 增加 且 Z≥1（ptr 设备不存在）" "POFF $POFF0->$POFF1 ptr=$PTR voff $V0->$V1 Z=$Z" PASS \
  || ck R2-HIDDEN "隐藏后首次竖推：内层 vertical_offset 增加 且 Z≥1" "POFF $POFF0->$POFF1 ptr=$PTR voff $V0->$V1 Z=$Z" FAIL "P 1280 1000; sleep 9.5; stick 4 24000 1500"

sec "RESTORE"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.2
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
L ""; L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
