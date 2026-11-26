#!/system/bin/sh
# verify_v169_extra.sh -- v1.69 发布字节（d31e5128）专项：
#   A 基线（APK/版本/助手/横屏）
#   B P 绝对定位六点闭环（走 root 控制通道 /data/adb/gpm/gpmctl.sock + `c` 复核）
#   C `?` 自检：CAP 13 项全 1、ERR=0
#   D LB/RB 连续拖拽三档（100/300/1500ms，引擎 drag end total）
#   E 滚轮模式（v_touch_scroll=false）：WHEEL=9 / SWIPE=0
#   F X+LB / X+RB 方向（helper SWIPE dx 符号）
#
# 以 root 运行：adb shell "su -c 'sh /data/local/tmp/verify_v169_extra.sh'"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
SOCK=/data/adb/gpm/gpmctl.sock
CTL=/data/local/tmp/gpmctl
OUT=/data/local/tmp/verify_v169_extra.result
SHOTS=/data/local/tmp/v169_shots
EXPECT_APK="${EXPECT_APK:-d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb}"
EXPECT_HELPER="${EXPECT_HELPER:-b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d}"
PASS=0; FAIL=0; FAILED=""
mkdir -p "$SHOTS" 2>/dev/null; : > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
ppath(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
vt(){ grep -o 'v_touch_scroll" value="[a-z]*"' "$(ppath)" 2>/dev/null | sed 's/.*value="//;s/"//'; }
set_vt(){ sed -i "s/v_touch_scroll\" value=\"[a-z]*\"/v_touch_scroll\" value=\"$1\"/" "$(ppath)" 2>/dev/null
  am force-stop $PKG >/dev/null 2>&1; sleep 1.2
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0; while [ $i -lt 25 ]; do i=$((i+1)); sleep 0.6; pidof $PKG >/dev/null 2>&1 && [ "$(vt)" = "$1" ] && { sleep 2.5; return 0; }; done; return 1; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
drag_total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/^.*total=//;s/px.*//'; }
drag_dur(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/.*dur=//;s/ms.*//'; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
WHEEL_SUM(){ grep -a '^WHEEL' "$HL" 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i ~ /^h=/) {gsub("h=","",$i); s+=$i}}} END{print s+0}'; }

# ---------------------------------------------------------------- A 基线
sec "A 基线（v1.69 release 字节 d31e5128）"
wake; pin
APKH=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
HELH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
VER=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//'); VC=$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
MODPROP=$(grep -E '^(version|versionCode)=' /data/adb/modules/gpm_dex/module.prop | tr '\n' ' ')
PTVER=$(dumpsys package $PAD | grep -m1 versionName | sed 's/.*=//'); PTV=$(dumpsys package $PAD | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
PTH=$(sha256sum "$(pm path $PAD | sed 's/package://')" 2>/dev/null | awk '{print $1}')
L "  apk=$APKH"; L "  helper=$HELH module=$MODH"; L "  version=$VER/$VC module.prop=$MODPROP"; L "  padtest=$PTVER/$PTV sha=$PTH"
[ "$APKH" = "$EXPECT_APK" ] && ck V169-APK "设备 base.apk == 发布 dexpad-v1.69.apk" "$APKH" PASS || ck V169-APK "设备 base.apk == 发布 dexpad-v1.69.apk" "$APKH" FAIL "pm path"
{ [ "$HELH" = "$EXPECT_HELPER" ] && [ "$MODH" = "$EXPECT_HELPER" ]; } && ck V169-HELPER "助手 gpm==模块==b806f39b" "$HELH / $MODH" PASS || ck V169-HELPER "助手 gpm==模块==b806f39b" "$HELH / $MODH" FAIL "sha256sum"
{ [ "$VER" = "1.69" ] && [ "$VC" = "71" ] && echo "$MODPROP" | grep -q 'v1.69' && echo "$MODPROP" | grep -q 'versionCode=71'; } && ck V169-VER "versionName=1.69 / versionCode=71（module.prop v1.69/71）" "$VER/$VC | $MODPROP" PASS || ck V169-VER "versionName=1.69 / versionCode=71" "$VER/$VC | $MODPROP" FAIL "dumpsys"
{ [ "$PTVER" = "1.4" ] && [ "$PTV" = "5" ] && [ "$PTH" = "0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d" ]; } && ck V169-PADTEST "padtest v1.4/5 且 sha==0f4a9191（t60 最终）" "$PTVER/$PTV $PTH" PASS || ck V169-PADTEST "padtest v1.4/5 sha==0f4a9191" "$PTVER/$PTV $PTH" FAIL "pm path com.dennis.padtest"
ASZ=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
ROT=$(settings get system user_rotation); ACC=$(settings get system accelerometer_rotation)
{ [ "$ROT" = "1" ] && [ "$ACC" = "0" ] && [ "$ASZ" = "2560x1600" ]; } && ck V169-LAND "默认横屏 user_rotation=1 accel=0 app=2560x1600" "rot=$ROT accel=$ACC app=$ASZ" PASS || ck V169-LAND "默认横屏" "rot=$ROT accel=$ACC app=$ASZ" FAIL

# ---------------------------------------------------------------- B P 六点闭环（控制通道）
sec "B P 绝对定位六点（root 控制通道 gpmctl.sock + c 复核，阈值 ≤8px）"
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.0
ctl j >/dev/null 2>&1; sleep 0.8
FAILP=""; NOK=0
for pt in "400 1200" "2000 300" "102 102" "2447 1498" "1282 802" "700 1000"; do
  set -- $pt; X=$1; Y=$2
  REPLY=$(ctl P $X $Y 2560 1600 2>&1)
  ERRL=$(echo "$REPLY" | grep -a 'POSPTR' | tail -1)
  FIN=$(echo "$REPLY" | grep -a 'final=' | tail -1 | sed 's/.*final=//;s/ .*//')
  ER=$(echo "$REPLY" | grep -a 'err=' | tail -1 | sed 's/.*err=//;s/ .*//')
  CUR=$(ctl c 2>&1 | grep -a 'CURSOR' | tail -1)
  L "  P $X,$Y → final=[$FIN] err=[$ER] | $CUR"
  MAXE=$(echo "$ER" | awk -F, '{a=$1<0?-$1:$1; b=$2<0?-$2:$2; print (a>b)?a:b}')
  if [ -n "$FIN" ] && [ -n "$MAXE" ] && [ "$MAXE" -le 8 ]; then NOK=$((NOK+1)); else FAILP="$FAILP $X,$Y(err=$ER)"; fi
done
[ "$NOK" -eq 6 ] && ck V169-P6 "P 六点落点误差 ≤8px（六点全过）" "6/6 通过" PASS || ck V169-P6 "P 六点落点误差 ≤8px（六点全过）" "$NOK/6 通过；失败:$FAILP" FAIL "gpmctl sock P <x> <y> 2560 1600; gpmctl sock c"

# ---------------------------------------------------------------- C `?` 自检
sec "C 自检 CAP 13 项 / ERR=0"
SELF=$(ctl '?' 2>&1)
CAPS=$(echo "$SELF" | grep -ac '^CAP ')
CAP1=$(echo "$SELF" | grep -a '^CAP ' | grep -acE '1$')
ERRS=$(echo "$SELF" | grep -ac '^ERR ')
L "  CAP lines=$CAPS all1=$CAP1 ERR lines=$ERRS"
{ [ "$CAPS" -ge 13 ] && [ "$CAP1" -eq "$CAPS" ] && [ "$ERRS" -eq 0 ]; } && ck V169-CAP "问号自检：CAP ≥13 且全部=1、ERR=0" "CAP=$CAPS all1=$CAP1 ERR=$ERRS" PASS || ck V169-CAP "问号自检：CAP ≥13 全 1、ERR=0" "CAP=$CAPS all1=$CAP1 ERR=$ERRS" FAIL "gpmctl sock ?"

# ---------------------------------------------------------------- D 拖拽三档
sec "D LB/RB 连续拖拽三档（100/300/1500ms）"
set_vt true >/dev/null 2>&1
starts; logcat -c
$VG key 311 100 400 >/dev/null 2>&1; sleep 0.7
T100=$(drag_total); D100=$(drag_dur)
starts; logcat -c
$VG key 311 300 400 >/dev/null 2>&1; sleep 0.8
T300=$(drag_total); D300=$(drag_dur)
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.0
T1500=$(drag_total); D1500=$(drag_dur); S=$(swipe_n); W=$(wheel_n)
L "  100ms=$T100 (${D100}ms) 300ms=$T300 (${D300}ms) 1500ms=$T1500 (${D1500}ms) SWIPE=$S WHEEL=$W"
{ [ -n "$T100" ] && [ "$T100" -le 150 ] && [ "$T100" -gt 0 ]; } && ck V169-DRAG100 "100ms 位移 0<t≤150px" "${T100}px" PASS || ck V169-DRAG100 "100ms 位移 0<t≤150px" "${T100:-none}px" FAIL "vgpad key 311 100 400"
{ [ -n "$T300" ] && [ "$T300" -le 450 ] && [ "$T300" -gt "$T100" ]; } && ck V169-DRAG300 "300ms 位移 ≤450px 且单调" "${T300}px" PASS || ck V169-DRAG300 "300ms 位移 ≤450px 且单调" "${T300:-none}px" FAIL "vgpad key 311 300 400"
{ [ -n "$T1500" ] && [ "$T1500" -ge 1200 ] && [ "$T1500" -le 2200 ]; } && ck V169-DRAG1500 "1500ms 位移 ∈[1200,2200]px" "${T1500}px" PASS || ck V169-DRAG1500 "1500ms 位移 ∈[1200,2200]px" "${T1500:-none}px" FAIL "vgpad key 311 1500 400"
{ [ "$S" -eq 0 ] && [ "$W" -eq 0 ]; } && ck V169-DRAGPURE "拖拽期间 SWIPE=0 WHEEL=0（纯 d/m/e）" "SWIPE=$S WHEEL=$W" PASS || ck V169-DRAGPURE "拖拽期间 SWIPE=0 WHEEL=0" "SWIPE=$S WHEEL=$W" FAIL "grep helper.log"

# ---------------------------------------------------------------- E 滚轮模式
sec "E 滚轮模式（v_touch_scroll=false）：9 WHEEL / 0 SWIPE"
if set_vt false; then ck V169-VTOFF "release 包 v_touch_scroll=false 生效（sed prefs + 强制重启引擎）" "vtouch=$(vt) engine=$(pidof $PKG)" PASS
else ck V169-VTOFF "release 包 v_touch_scroll=false 生效" "vtouch=$(vt)" FAIL "sed prefs"; fi
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.2
W1=$(wheel_n); S1=$(swipe_n); SUM=$(WHEEL_SUM)
L "  wheel RB 1.5s: WHEEL=$W1 SWIPE=$S1 sum_h=$SUM"
{ [ "$W1" -ge 6 ] && [ "$S1" -eq 0 ]; } && ck V169-WHEEL "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W1 SWIPE=$S1 sum_h=$SUM" PASS || ck V169-WHEEL "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W1 SWIPE=$S1" FAIL "vgpad key 311 1500 (vt=false)"
set_vt true >/dev/null 2>&1
ck V169-RESTORE "恢复 v_touch_scroll=true" "vtouch=$(vt) engine=$(pidof $PKG)" "$([ "$(vt)" = "true" ] && echo PASS || echo FAIL)" "sed prefs"

# ---------------------------------------------------------------- F X+LB / X+RB 方向
sec "F X+LB / X+RB 横向翻页方向（helper SWIPE dx 符号）"
starts
: > "$HL"; logcat -c
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 1.2
S3=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
x1=$(echo "$S3" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$S3" | awk '{print $5}' | cut -d, -f1)
dx3=0; [ -n "$x1" ] && [ -n "$x2" ] && dx3=$((x2 - x1))
[ -n "$S3" ] && [ "$dx3" -gt 0 ] && ck V169-XLB "X+LB → dx>0（上一页方向）" "dx=+$dx3" PASS || ck V169-XLB "X+LB → dx>0" "dx=${dx3} sw=[$S3]" FAIL "vgpad combo 307 310 300 2600"
: > "$HL"; logcat -c
$VG combo 307 311 300 2600 >/dev/null 2>&1; sleep 1.2
S4=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
y1=$(echo "$S4" | awk '{print $3}' | cut -d, -f1); y2=$(echo "$S4" | awk '{print $5}' | cut -d, -f1)
dx4=0; [ -n "$y1" ] && [ -n "$y2" ] && dx4=$((y2 - y1))
[ -n "$S4" ] && [ "$dx4" -lt 0 ] && ck V169-XRB "X+RB → dx<0（下一页方向）" "dx=$dx4" PASS || ck V169-XRB "X+RB → dx<0" "dx=${dx4} sw=[$S4]" FAIL "vgpad combo 307 311 300 2600"

# ---------------------------------------------------------------- restore
sec "RESTORE"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.5
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) vtouch=$(vt) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) app=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)"
L ""; L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
