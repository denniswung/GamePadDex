#!/system/bin/sh
# verify_v170_extra.sh -- v1.70 发布字节（05f4f11f）专项
#   A 基线（APK/版本/助手/padtest/横屏）
#   B LB/RB 连续拖拽三档（100/300/1500ms）
#   C 滚轮模式（v_touch_scroll=false）：WHEEL=9 / SWIPE=0
#   D 控制通道拖拽 d/m/e（v1.70 产品级化）：padtest instrumentation.vertical_offset 单调增 + 故障码 + auto-up
#   E P 六点（root 控制通道）
#   F X+LB / X+RB 方向
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
SOCK=/data/adb/gpm/gpmctl.sock
CTL=/data/local/tmp/gpmctl
OUT=/data/local/tmp/verify_v170_extra.result
EXPECT_APK="${EXPECT_APK:-05f4f11f2e48b498556abc35ea58bbc873f032128529d83d6abe9ea5eced876c}"
EXPECT_HELPER="${EXPECT_HELPER:-eb0b5dfc6d5403b30d8200467f773e628729ea5290d1574aeb5651bf33c8c31c}"
EXPECT_PADTEST="${EXPECT_PADTEST:-0f4a91911360cb4051fff9b54711508e4dc90de797be6ec0e55e83e9a967056d}"
PASS=0; FAIL=0; FAILED=""
: > "$OUT"
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
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.6; cmd statusbar collapse >/dev/null 2>&1; sleep 0.5; }
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
drag_total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/^.*total=//;s/px.*//'; }
drag_dur(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end total=' | tail -1 | sed 's/.*dur=//;s/ms.*//'; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
export_json(){ am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
  sleep 1.2; logcat -d | grep -a 'EXPORT what=report' | tail -1 | sed 's/.*path=//;s/ size=.*//'; }
field(){ grep -o "\"$2\": *[0-9-]*" "$1" 2>/dev/null | head -1 | sed 's/.*: *//'; }
voff(){ local f=$(export_json); [ -z "$f" ] && { echo ""; return; }; field "$f" vertical_offset; }
hx(){ local f=$(export_json); [ -z "$f" ] && { echo ""; return; }; field "$f" horizontal_scroll_x; }

# ---------------------------------------------------------------- A 基线
sec "A 基线（v1.70 release 字节 05f4f11f）"
wake; pin
APKH=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
HELH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
VER=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//'); VC=$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
MODPROP=$(grep -E '^(version|versionCode)=' /data/adb/modules/gpm_dex/module.prop | tr '\n' ' ')
PTVER=$(dumpsys package $PAD | grep -m1 versionName | sed 's/.*=//'); PTV=$(dumpsys package $PAD | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
PTH=$(sha256sum "$(pm path $PAD | sed 's/package://')" 2>/dev/null | awk '{print $1}')
ASZ=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
ROT=$(settings get system user_rotation); ACC=$(settings get system accelerometer_rotation)
L "  apk=$APKH"; L "  helper=$HELH module=$MODH"; L "  version=$VER/$VC module.prop=$MODPROP"; L "  padtest=$PTVER/$PTV sha=$PTH"; L "  rot=$ROT accel=$ACC app=$ASZ"
[ "$APKH" = "$EXPECT_APK" ] && ck V170-APK "设备 base.apk == 发布 dexpad-v1.70.apk" "$APKH" PASS || ck V170-APK "设备 base.apk == 发布 dexpad-v1.70.apk" "$APKH" FAIL "pm path"
{ [ "$HELH" = "$EXPECT_HELPER" ] && [ "$MODH" = "$EXPECT_HELPER" ]; } && ck V170-HELPER "助手 gpm==模块==eb0b5dfc" "$HELH / $MODH" PASS || ck V170-HELPER "助手 gpm==模块==eb0b5dfc" "$HELH / $MODH" FAIL "sha256sum"
{ [ "$VER" = "1.70" ] && [ "$VC" = "72" ] && echo "$MODPROP" | grep -q 'v1.70' && echo "$MODPROP" | grep -q 'versionCode=72'; } && ck V170-VER "versionName=1.70 / versionCode=72（module.prop v1.70/72）" "$VER/$VC | $MODPROP" PASS || ck V170-VER "versionName=1.70 / versionCode=72" "$VER/$VC | $MODPROP" FAIL "dumpsys"
{ [ "$PTVER" = "1.4" ] && [ "$PTV" = "5" ] && [ "$PTH" = "$EXPECT_PADTEST" ]; } && ck V170-PADTEST "padtest v1.4/5 且 sha==0f4a9191（不升 v1.5）" "$PTVER/$PTV $PTH" PASS || ck V170-PADTEST "padtest v1.4/5 sha==0f4a9191" "$PTVER/$PTV $PTH" FAIL "pm path com.dennis.padtest"
{ [ "$ROT" = "1" ] && [ "$ACC" = "0" ] && [ "$ASZ" = "2560x1600" ]; } && ck V170-LAND "默认横屏 user_rotation=1 accel=0 app=2560x1600" "rot=$ROT accel=$ACC app=$ASZ" PASS || ck V170-LAND "默认横屏" "rot=$ROT accel=$ACC app=$ASZ" FAIL

# ---------------------------------------------------------------- B 拖拽三档
sec "B LB/RB 连续拖拽三档（100/300/1500ms）"
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
{ [ -n "$T100" ] && [ "$T100" -le 150 ] && [ "$T100" -gt 0 ]; } && ck V170-DRAG100 "100ms 位移 0<t≤150px" "${T100}px" PASS || ck V170-DRAG100 "100ms 位移 0<t≤150px" "${T100:-none}px" FAIL "vgpad key 311 100 400"
{ [ -n "$T300" ] && [ "$T300" -le 450 ] && [ "$T300" -gt "$T100" ]; } && ck V170-DRAG300 "300ms 位移 ≤450px 且单调" "${T300}px" PASS || ck V170-DRAG300 "300ms 位移 ≤450px 且单调" "${T300:-none}px" FAIL "vgpad key 311 300 400"
{ [ -n "$T1500" ] && [ "$T1500" -ge 1200 ] && [ "$T1500" -le 2200 ]; } && ck V170-DRAG1500 "1500ms 位移 ∈[1200,2200]px" "${T1500}px" PASS || ck V170-DRAG1500 "1500ms 位移 ∈[1200,2200]px" "${T1500:-none}px" FAIL "vgpad key 311 1500 400"
{ [ "$S" -eq 0 ] && [ "$W" -eq 0 ]; } && ck V170-DRAGPURE "拖拽期间 SWIPE=0 WHEEL=0（纯 d/m/e）" "SWIPE=$S WHEEL=$W" PASS || ck V170-DRAGPURE "拖拽期间 SWIPE=0 WHEEL=0" "SWIPE=$S WHEEL=$W" FAIL "grep helper.log"

# ---------------------------------------------------------------- C 滚轮
sec "C 滚轮模式（v_touch_scroll=false）：9 WHEEL / 0 SWIPE"
if set_vt false; then ck V170-VTOFF "release 包 v_touch_scroll=false 生效（sed prefs + 强制重启引擎）" "vtouch=$(vt) engine=$(pidof $PKG)" PASS
else ck V170-VTOFF "release 包 v_touch_scroll=false 生效" "vtouch=$(vt)" FAIL "sed prefs"; fi
starts; : > "$HL"; logcat -c
$VG key 311 1500 400 >/dev/null 2>&1; sleep 1.2
W1=$(wheel_n); S1=$(swipe_n)
L "  wheel RB 1.5s: WHEEL=$W1 SWIPE=$S1"
{ [ "$W1" -ge 6 ] && [ "$S1" -eq 0 ]; } && ck V170-WHEEL "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0（投递 PASS；内容位移见 FINAL3 = BLOCKED）" "WHEEL=$W1 SWIPE=$S1" PASS || ck V170-WHEEL "滚轮 RB 1.5s：WHEEL≥6 且 SWIPE=0" "WHEEL=$W1 SWIPE=$S1" FAIL "vgpad key 311 1500 (vt=false)"
set_vt true >/dev/null 2>&1
ck V170-RESTORE "恢复 v_touch_scroll=true" "vtouch=$(vt) engine=$(pidof $PKG)" "$([ "$(vt)" = "true" ] && echo PASS || echo FAIL)" "sed prefs"

# ---------------------------------------------------------------- D 控制通道拖拽
sec "D 控制通道拖拽 d/m/e（v1.70 产品级化）"
starts
ctl j >/dev/null 2>&1; sleep 0.7
# D1 竖向拖拽（锚点在列表区 1280,700）→ vertical_offset 增加
ctl P 1280 700 2560 1600 >/dev/null 2>&1; sleep 0.6
V0=$(voff)
R1=$(ctl d 0 1280 700 2>&1 | tail -1); R2=$(ctl m 0 0 -400 400 2>&1 | tail -1); R3=$(ctl e 0 2>&1 | tail -1); sleep 0.8
V1=$(voff)
L "  D1 vertical: [$R1] [$R2] [$R3] voff $V0 -> $V1"
{ [ -n "$V1" ] && [ -n "$V0" ] && [ "$V1" -gt "$V0" ]; } && ck V170-CTLDRAG-V "控制通道 d/m/e 竖向：vertical_offset 增加（内容滚动）" "voff $V0->$V1" PASS || ck V170-CTLDRAG-V "控制通道 d/m/e 竖向：vertical_offset 增加" "voff $V0->$V1" FAIL "gpmctl sock d 0 1280 700; m 0 0 -400 400; e 0"
# D2 横向拖拽（锚点在分页区 1280,1000）→ horizontal_scroll_x 增加
ctl P 1280 1000 2560 1600 >/dev/null 2>&1; sleep 0.6
H0=$(hx)
ctl d 0 1280 1000 >/dev/null 2>&1; ctl m 0 -500 0 400 >/dev/null 2>&1; sleep 0.5; ctl e 0 >/dev/null 2>&1; sleep 0.8
H1=$(hx)
L "  D2 horizontal: hx $H0 -> $H1"
{ [ -n "$H1" ] && [ -n "$H0" ] && [ "$H1" -gt "$H0" ]; } && ck V170-CTLDRAG-H "控制通道 d/m/e 横向：horizontal_scroll_x 增加（分页滚动）" "hx $H0->$H1" PASS || ck V170-CTLDRAG-H "控制通道 d/m/e 横向：horizontal_scroll_x 增加" "hx $H0->$H1" FAIL "d 0 1280 1000; m 0 -500 0 400; e 0"
# D3 auto-up：不发 e，2.6s 后自动抬指，之后 e 不报错
ctl P 1280 1100 2560 1600 >/dev/null 2>&1; sleep 0.6
V2=$(voff)
ctl d 0 1280 1100 >/dev/null 2>&1; ctl m 0 0 -400 400 >/dev/null 2>&1; sleep 2.6
V3=$(voff)
R4=$(ctl e 0 2>&1 | tail -1)
AU=$(grep -ac 'why=auto-up' /data/adb/gpm/helper.log 2>/dev/null)
L "  D3 auto-up: voff $V2 -> $V3 (no e, wait 2.6s) then e -> [$R4] auto-up_lines=$AU"
{ [ -n "$V3" ] && [ -n "$V2" ] && [ "$V3" -gt "$V2" ] && [ "$AU" -ge 1 ] && echo "$R4" | grep -q 'OK e'; } && ck V170-AUTOUP "不发 e、2.6s 后自动抬指（helper why=auto-up），后续 e 正常" "voff $V2->$V3 auto-up=$AU e=[$R4]" PASS || ck V170-AUTOUP "auto-up 生效且状态干净" "voff $V2->$V3 auto-up=$AU e=[$R4]" FAIL "d; m; sleep 2.6; e"
E1=$(ctl d 2>&1 | grep -a 'ERR' | tail -1)
E2=$(ctl m 0 -100 100 100 2>&1 | grep -a 'ERR' | tail -1)
L "  故障码：d(无参)=[$E1] m(无down)=[$E2]"
{ [ -n "$E1" ] && [ -n "$E2" ]; } && ck V170-CTLERR "控制通道故障码：d 缺参 → ERR、m 无 down → ERR_STATE/no-down" "d=[$E1] m=[$E2]" PASS || ck V170-CTLERR "控制通道故障码" "d=[$E1] m=[$E2]" FAIL "gpmctl sock d; gpmctl sock m 0 -100 100 100"

# ---------------------------------------------------------------- E P 六点
sec "E P 绝对定位六点（阈值 ≤8px）"
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.0
ctl j >/dev/null 2>&1; sleep 0.8
NOK=0; FAILP=""
for pt in "400 1200" "2000 300" "102 102" "2447 1498" "1282 802" "700 1000"; do
  set -- $pt; X=$1; Y=$2
  REPLY=$(ctl P $X $Y 2560 1600 2>&1)
  ER=$(echo "$REPLY" | grep -a 'err=' | tail -1 | sed 's/.*err=//;s/ .*//')
  CUR=$(ctl c 2>&1 | grep -a 'CURSOR' | tail -1)
  L "  P $X,$Y err=[$ER] | $CUR"
  MAXE=$(echo "$ER" | awk -F, '{a=$1<0?-$1:$1; b=$2<0?-$2:$2; print (a>b)?a:b}')
  if [ -n "$MAXE" ] && [ "$MAXE" -le 8 ]; then NOK=$((NOK+1)); else FAILP="$FAILP $X,$Y(err=$ER)"; fi
done
[ "$NOK" -eq 6 ] && ck V170-P6 "P 六点落点误差 ≤8px（六点全过）" "6/6" PASS || ck V170-P6 "P 六点落点误差 ≤8px" "$NOK/6；失败:$FAILP" FAIL "gpmctl sock P <x> <y> 2560 1600"

# ---------------------------------------------------------------- F X+LB / X+RB
sec "F X+LB / X+RB 横向翻页方向"
starts
: > "$HL"; logcat -c
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 1.2
S3=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
x1=$(echo "$S3" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$S3" | awk '{print $5}' | cut -d, -f1)
dx3=0; [ -n "$x1" ] && [ -n "$x2" ] && dx3=$((x2 - x1))
[ -n "$S3" ] && [ "$dx3" -gt 0 ] && ck V170-XLB "X+LB → dx>0（上一页方向）" "dx=+$dx3" PASS || ck V170-XLB "X+LB → dx>0" "dx=${dx3}" FAIL "vgpad combo 307 310 300 2600"
: > "$HL"; logcat -c
$VG combo 307 311 300 2600 >/dev/null 2>&1; sleep 1.2
S4=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
y1=$(echo "$S4" | awk '{print $3}' | cut -d, -f1); y2=$(echo "$S4" | awk '{print $5}' | cut -d, -f1)
dx4=0; [ -n "$y1" ] && [ -n "$y2" ] && dx4=$((y2 - y1))
[ -n "$S4" ] && [ "$dx4" -lt 0 ] && ck V170-XRB "X+RB → dx<0（下一页方向）" "dx=$dx4" PASS || ck V170-XRB "X+RB → dx<0" "dx=${dx4}" FAIL "vgpad combo 307 311 300 2600"

sec "RESTORE"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.5
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) vtouch=$(vt) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
L ""; L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$OUT"
[ "$FAIL" -eq 0 ]
