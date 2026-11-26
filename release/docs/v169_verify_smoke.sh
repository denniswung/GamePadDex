#!/system/bin/sh
# v166_release_smoke.sh -- v1.66 **release 构建**（发布字节 73477eca）装机后冒烟验证
#
# Why this script exists:
#   The published APK is an assembleRelease build (debuggable=false), and the app's
#   DebugReceiver deliberately ignores HCMD/DEBUG broadcasts in non-debuggable builds
#   (DebugReceiver.kt:21-22). Therefore the full A~K auto suite (which uses those
#   broadcasts for A5's pointer probe, G3's pref override and J6/J7's force_landscape)
#   cannot run unmodified on the release bytes. Those four items stay covered by the
#   t15 full-suite run on the identical app source (debug variant d2194406).
#
#   This script re-checks, on the published release bytes, every user-visible behaviour
#   using only public mechanisms: vgpad (uinput gamepad) + padtest (real injected
#   pointer events) + uiautomator (real page positions) + helper.log + settings/dumpsys.
#
# Usage: adb shell "su -c 'sh /data/local/tmp/v166_release_smoke.sh'"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
MOD=/data/adb/modules/gpm_dex
RES=/data/local/tmp/v169_release_smoke.result
LOG=/data/local/tmp/v169_release_smoke.log
SHOTS=/data/local/tmp/v169_release_shots
EXPECT_APK="${EXPECT_APK:-d31e51285a0a3baa71a75ed2b7dca1a7f88697685ae982c35e2f807bfc92c7fb}"
EXPECT_HELPER="${EXPECT_HELPER:-b806f39ba51278a73aad121be4019820b7961dcb0935971b64d3a02373cd2a4d}"
PASS=0; FAIL=0; FAILED=""
mkdir -p "$SHOTS" 2>/dev/null
: > "$LOG"; : > "$RES"

L() { echo "$@" | tee -a "$LOG"; }
sec() { echo "" | tee -a "$LOG"; echo "===== $* =====" | tee -a "$LOG"; echo "===== $* =====" >> "$RES"; }
ck() { # id threshold measured PASS|FAIL [repro]
  if [ "$4" = "PASS" ]; then
    PASS=$((PASS + 1)); printf '[%s] PASS | 阈值: %s | 实测: %s\n' "$1" "$2" "$3" | tee -a "$RES"
  else
    FAIL=$((FAIL + 1)); FAILED="$FAILED $1"; printf '[%s] FAIL | 阈值: %s | 实测: %s\n' "$1" "$2" "$3" | tee -a "$RES"
    [ -n "$5" ] && printf '     REPRO: %s\n' "$5" | tee -a "$RES"
  fi
  printf '  [%s] %s | %s\n' "$4" "$1" "$3" >> "$LOG"
}
now_ms() { awk '{printf "%d", $1*1000}' /proc/uptime 2>/dev/null; }

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin() { settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
startp() { am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.2; }
starts() { am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; }
l3() { $VG key 317 100 0 >/dev/null 2>&1; sleep 1.2; }
click() { $VG key 304 60 0 >/dev/null 2>&1; sleep 0.6; }
stick() { $VG stick "$1" "$2" "$3" "${4:-0}" >/dev/null 2>&1; }

wf() { dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//;s/ .*//'; }
topact() { dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
focus() { dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*mCurrentFocus=//;s/}.*/}/'; }
shade() { dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*NotificationShade'; }
appsize() { dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1; }
rotlock() { cmd window user-rotation 2>/dev/null | head -1 | tr -d '\r'; }
cxy() { logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
entry() {
  case "$1" in
    key_enter) logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER' ;;
    mouse_click) logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down' ;;
  esac
}
hlc() { grep -ac "$1" "$HL" 2>/dev/null; }
pickZ() { grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" 'NF==4{k=($1==$3)?"Z":"V"; if(k!=want) next; d=(k=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++} END{printf "%d %d", n+0, s+0}'; }
scroll_metrics() {
  local attempt=0
  while [ $attempt -lt 3 ]; do
    attempt=$((attempt + 1))
    timeout 12 uiautomator dump /sdcard/v166_ui.xml >/dev/null 2>&1
    sed 's/></>\n</g' /sdcard/v166_ui.xml > /sdcard/v166_ui.lines 2>/dev/null
    PY=-1; HS=0; scroll_parse
    [ "$PY" != "-1" ] && return 0
    sleep 0.7
  done
}
scroll_parse() {
  local n l b x1 y1 x2 y2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v166_ui.lines 2>/dev/null)
    [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')
    [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2 - x1))
    if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600 * (n - 1) + 600 - w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
}
appgeom() { logcat -d -s DexPad 2>/dev/null | grep -a 'geometry app=' | tail -1 | sed -n 's/.*geometry app=\([0-9]*x[0-9]*\).*/\1/p'; }

# ---------------------------------------------------------------- RS-0 基线
sec "RS-0 基线（v1.69 发布字节）"
wake; pin
apk=$(pm path $PKG 2>/dev/null | head -1 | sed 's/package://')
hash=$(sha256sum "$apk" 2>/dev/null | cut -d' ' -f1)
ver=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
vc=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
hhelp=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)
hmod=$(sha256sum $MOD/gpminput 2>/dev/null | cut -d' ' -f1)
L "  apk=$apk"
L "  apk_sha256=$hash size=$(stat -c %s "$apk" 2>/dev/null)"
L "  versionName=$ver versionCode=$vc"
L "  helper=$hhelp module=$hmod"
if [ "$hash" = "$EXPECT_APK" ]; then ck RS0-APK "设备 base.apk sha256 == 发布 dexpad-v1.69.apk $EXPECT_APK" "$hash ($(stat -c %s "$apk" 2>/dev/null)B)" PASS
else ck RS0-APK "设备 base.apk sha256 == 发布 dexpad-v1.69.apk $EXPECT_APK" "$hash" FAIL "pm path $PKG; sha256sum base.apk"; fi
if [ "$ver" = "1.69" ] && [ "$vc" = "71" ]; then ck RS0-VER "versionName=1.69 versionCode=71" "versionName=$ver versionCode=$vc" PASS
else ck RS0-VER "versionName=1.69 versionCode=71" "versionName=$ver versionCode=$vc" FAIL "dumpsys package $PKG"; fi
if [ "$hhelp" = "$EXPECT_HELPER" ] && [ "$hmod" = "$EXPECT_HELPER" ]; then ck RS0-HELPER "/data/adb/gpm == 模块目录 == 发布 gpminput-v1.69 $EXPECT_HELPER" "$hhelp / $hmod" PASS
else ck RS0-HELPER "/data/adb/gpm == 模块目录 == 发布 gpminput-v1.69" "$hhelp / $hmod" FAIL "sha256sum /data/adb/gpm/gpminput $MOD/gpminput"; fi
asz=$(appsize); w=${asz%x*}; h=${asz#*x}
rot=$(settings get system user_rotation | tr -d '\r'); acc=$(settings get system accelerometer_rotation | tr -d '\r')
geom=$(appgeom)
if [ "$rot" = "1" ] && [ "$acc" = "0" ] && [ "$w" -gt "$h" ]; then
  ck RS0-LAND "默认启动即横屏：user_rotation=1 accel=0 app 宽>高（dumpsys display rotation 1；本机 mLandscapeRotation=ROTATION_0 常量）" "user_rotation=$rot accel=$acc app=$asz engine=${geom:-n/a} dumpsys_rot=1" PASS
else
  ck RS0-LAND "默认启动即横屏：user_rotation=1 accel=0 app 宽>高" "user_rotation=$rot accel=$acc app=$asz" FAIL "settings get system user_rotation; dumpsys window displays"
fi
L "  wake=$(wf) focus=$(focus)"

# ---------------------------------------------------------------- RS-1 L3 居中 + A=鼠标点击（D5/D6 行为）
sec "RS-1 L3 居中 + A=鼠标点击（release 字节）"
startp
cmd statusbar collapse >/dev/null 2>&1
l3; logcat -c; click
A=$(cxy)
mc=$(entry mouse_click); ke=$(entry key_enter)
err=$(logcat -d -s DexPad 2>/dev/null | grep -a 'CENTER_OK' | tail -1 | sed -n 's/.*err=\([-0-9]*\),\([-0-9]*\).*/\1,\2/p')
l3ms=$(logcat -d -s DexPad 2>/dev/null | grep -ao 'l3TookMs=[0-9]*' | tail -1 | sed 's/.*=//')
L "  L3 click=[$A] err=[$err] mouse_click=$mc key_enter=$ke l3TookMs=${l3ms:-n/a}"
dxy=$(awk -v a="$A" 'BEGIN{split(a,p," "); if(p[1]==""){print 999; exit} dx=p[1]-1280; dy=p[2]-800; if(dx<0)dx=-dx; if(dy<0)dy=-dy; print (dx>dy)?dx:dy}')
if [ -n "$A" ] && [ "$dxy" -le 40 ] && [ "$mc" -ge 1 ] && [ "$ke" -eq 0 ]; then
  ck RS1-L3 "L3 居中落点距 (1280,800) ≤40px 且 A=鼠标点击（mouse_click≥1 key_enter=0）" "click=[$A] err=[$err] d=${dxy}px mouse_click=$mc key_enter=$ke l3TookMs=${l3ms:-n/a}" PASS
else
  ck RS1-L3 "L3 居中落点距 (1280,800) ≤40px 且 A=鼠标点击" "click=[$A] d=${dxy}px mouse_click=$mc key_enter=$ke" FAIL "vgpad key 317 100 0; vgpad key 304 60 0"
fi

# ---------------------------------------------------------------- RS-2 光标 dpi（鼠标真的移动）
sec "RS-2 光标 dpi（左摇杆满推 300ms 后真实点击落点位移）"
startp
cmd statusbar collapse >/dev/null 2>&1
l3
logcat -c
stick 0 30000 300    # ABS_X (left stick) full push right
sleep 0.7
click
B=$(cxy)
dx=$(awk -v a="$B" 'BEGIN{split(a,p," "); if(p[1]==""){print -1; exit} print p[1]-1280}')
L "  move: click=[$B] dx_from_center=$dx"
if [ -n "$B" ] && [ "$dx" -ge 1000 ]; then
  ck RS2-MOVE "300ms 满推左摇杆右后落点相对中心右移 ≥1000px（鼠标设备可移动 + 光标夹取到边缘 2559）" "click=[$B] dx=+${dx}px" PASS
else
  ck RS2-MOVE "300ms 满推左摇杆右后落点相对中心右移 ≥1000px" "click=[$B] dx=${dx}px" FAIL "l3; vgpad stick 0 30000 300; vgpad key 304 60 0"
fi

# ---------------------------------------------------------------- RS-3 滑动（竖/横，真实页面位移）
sec "RS-3 右摇杆滑动：竖向/横向真实页面位移 + helper 手势轴向"
starts
cmd statusbar collapse >/dev/null 2>&1
l3
: > "$HL"; logcat -c
scroll_metrics; py0=$PY; hs0=$HS
stick 4 24000 1500
sleep 1.2
scroll_metrics; dpy=$((py0 - PY)); [ "$dpy" -lt 0 ] && dpy=$((-dpy))
dhs0=$((HS - hs0)); [ "$dhs0" -lt 0 ] && dhs0=$((-dhs0))
z=$(pickZ Z); zn=${z%% *}; zv=${z##* }
v=$(pickZ V); vn=${v%% *}
L "  vertical: PY $py0 -> $PY d=$dpy HS d=$dhs0 Zn=$zn Vn=$vn"
if [ "$dpy" -ge 1000 ] && [ "$dhs0" -le 20 ] && [ "$zn" -ge 1 ] && [ "$vn" -eq 0 ]; then
  ck RS3-V "竖推 1.5s 页面纵向下移 ≥1000px（HS 变化 ≤20）且 helper 仅竖向手势 Z（V=0）" "PY $py0->$PY d=$dpy HS d=$dhs0 Zn=$zn Vn=$vn" PASS
else
  ck RS3-V "竖推 1.5s 页面纵向下移 ≥1000px（HS 变化 ≤20）且 helper 仅竖向手势 Z（V=0）" "PY $py0->$PY d=$dpy HS d=$dhs0 Zn=$zn Vn=$vn" FAIL "starts; l3; vgpad stick 4 24000 1500; uiautomator dump"
fi
: > "$HL"
scroll_metrics; hs1=$HS
stick 3 24000 1500
sleep 1.2
scroll_metrics; dhs=$((HS - hs1)); [ "$dhs" -lt 0 ] && dhs=$((-dhs))
v2=$(pickZ V); vn2=${v2%% *}; z2=$(pickZ Z); zn2=${z2%% *}
L "  horizontal: HS $hs1 -> $HS d=$dhs Vn=$vn2 Zn=$zn2"
if [ "$dhs" -ge 400 ] && [ "$vn2" -ge 1 ] && [ "$zn2" -eq 0 ]; then
  ck RS3-H "横推 1.5s 横向分页位移 ≥400px 且 helper 仅横向手势 V（Z=0）" "HS $hs1->$HS d=$dhs Vn=$vn2 Zn=$zn2" PASS
else
  ck RS3-H "横推 1.5s 横向分页位移 ≥400px 且 helper 仅横向手势 V（Z=0）" "HS $hs1->$HS d=$dhs Vn=$vn2 Zn=$zn2" FAIL "vgpad stick 3 24000 1500; uiautomator dump"
fi

# ---------------------------------------------------------------- RS-4 空闲隐藏后第一次推杆（t20 修复点）
sec "RS-4 指针空闲隐藏后第一次推杆（t20 修复点，release 字节）"
starts
cmd statusbar collapse >/dev/null 2>&1
sleep 0.5
logcat -c
poff0=$(hlc 'POINTER off')
scroll_metrics; pyh=$PY
sleep 9.5
poff1=$(hlc 'POINTER off')
hid=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
ptr_now=$(getevent -pl 2>/dev/null | grep -c 'Gamepad Mouse Pointer')
L "  idle 9.5s: POINTER off $poff0 -> $poff1, engine hidden=$hid, pointer device present=$ptr_now"
: > "$HL"
stick 4 24000 1500
sleep 1.2
scroll_metrics; dpyh=$((pyh - PY)); [ "$dpyh" -lt 0 ] && dpyh=$((-dpyh))
zh=$(pickZ Z); znh=${zh%% *}
L "  hidden first push: PY $pyh -> $PY d=$dpyh Zn=$znh"
if [ "$poff1" -gt "$poff0" ] && [ "$ptr_now" -eq 0 ] && [ "$dpyh" -ge 1000 ] && [ "$znh" -ge 1 ]; then
  ck RS4-HIDDEN "空闲隐藏（POINTER off 且设备不存在）后第一次竖推仍滚页 ≥1000px" "POINTER off $poff0->$poff1 ptr_dev=$ptr_now PY $pyh->$PY d=$dpyh Zn=$znh" PASS
else
  ck RS4-HIDDEN "空闲隐藏（POINTER off 且设备不存在）后第一次竖推仍滚页 ≥1000px" "POFF $poff0->$poff1 ptr_dev=$ptr_now dPY=$dpyh Zn=$znh" FAIL "starts; sleep 9.5; vgpad stick 4 24000 1500; uiautomator dump"
fi
# 隐藏首推后指针恢复可见（预期语义），再横推必须生效
cmd statusbar collapse >/dev/null 2>&1
scroll_metrics; hsh=$HS
stick 3 24000 2500
sleep 1.2
scroll_metrics; dhsh=$((HS - hsh)); [ "$dhsh" -lt 0 ] && dhsh=$((-dhsh))
if [ "$dhsh" -ge 400 ]; then
  ck RS4-HIDDEN-H "隐藏首推后横推仍生效（横向分页位移 ≥400px）" "HS $hsh->$HS d=$dhsh" PASS
else
  ck RS4-HIDDEN-H "隐藏首推后横推仍生效（横向分页位移 ≥400px）" "HS $hsh->$HS d=$dhsh" FAIL "vgpad stick 3 24000 2500"
fi

# ---------------------------------------------------------------- RS-5 Y+上 / Y+下 打开应用
sec "RS-5 Y+上→PiliPlus / Y+下→抖音（release 字节）"
am force-stop com.example.piliplus >/dev/null 2>&1
am force-stop com.ss.android.ugc.aweme >/dev/null 2>&1
$VG keyvhat 308 -1 500 2600 >/dev/null 2>&1
sleep 2.6
t1=$(topact)
o1=$(grep -a 'OPEN_APP' "$HL" 2>/dev/null | tail -1)
L "  Y+up top=$t1 | $o1"
case "$t1" in
  *piliplus*) ck RS5-YUP "Y+上 → 前台 com.example.piliplus/.MainActivity（helper OPEN_APP 组件启动）" "top=$t1 | $o1" PASS ;;
  *) ck RS5-YUP "Y+上 → 前台 PiliPlus" "top=$t1 | $o1" FAIL "vgpad keyvhat 308 -1 500 2600; dumpsys activity activities" ;;
esac
$VG keyvhat 308 1 500 2600 >/dev/null 2>&1
sleep 2.6
t2=$(topact)
o2=$(grep -a 'OPEN_APP' "$HL" 2>/dev/null | tail -1)
L "  Y+down top=$t2 | $o2"
case "$t2" in
  *aweme*) ck RS5-YDOWN "Y+下 → 前台 抖音（helper OPEN_APP 组件启动）" "top=$t2 | $o2" PASS ;;
  *) ck RS5-YDOWN "Y+下 → 前台 抖音" "top=$t2 | $o2" FAIL "vgpad keyvhat 308 1 500 2600; dumpsys activity activities" ;;
esac

# ---------------------------------------------------------------- RS-6 回归 6 项
sec "RS-6 回归（不得回退的 6 项，release 字节）"
startp
cmd statusbar collapse >/dev/null 2>&1
# I1 d-pad 粘性 + A 注入 DPAD_CENTER
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
mc1=$(entry mouse_click); ke1=$(entry key_enter)
L "  I1 d-pad then A: mouse_click=$mc1 key_enter=$ke1"
if [ "$mc1" -eq 0 ] && [ "$ke1" -ge 1 ]; then
  ck RS6-I1 "d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1）" "mouse_click=$mc1 key_enter=$ke1" PASS
else
  ck RS6-I1 "d-pad 粘性导航 + A 注入 DPAD_CENTER（mouse_click=0 key_enter≥1）" "mouse_click=$mc1 key_enter=$ke1" FAIL "vgpad hat 0 1 250 x2; vgpad key 304 60 0"
fi
# 摇杆后 A 恢复鼠标点击
stick 0 20000 250
sleep 0.5
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
mc2=$(entry mouse_click); ke2=$(entry key_enter)
if [ "$mc2" -ge 1 ] && [ "$ke2" -eq 0 ]; then
  ck RS6-I1B "摇杆移动后 A 恢复鼠标点击（mouse_click≥1 key_enter=0）" "mouse_click=$mc2 key_enter=$ke2" PASS
else
  ck RS6-I1B "摇杆移动后 A 恢复鼠标点击" "mouse_click=$mc2 key_enter=$ke2" FAIL "vgpad stick 0 20000 250; vgpad key 304 60 0"
fi
# I2 X 双击 → 多任务
logcat -c
$VG double 307 60 200 2600 >/dev/null 2>&1
sleep 1.6
t3=$(topact)
case "$t3" in
  *RecentsActivity*) ck RS6-I2 "X 双击（400ms 窗口）→ 前台 RecentsActivity" "top=$t3" PASS ;;
  *) ck RS6-I2 "X 双击（400ms 窗口）→ 前台 RecentsActivity" "top=$t3" FAIL "vgpad double 307 60 200 2600" ;;
esac
startp
cmd statusbar collapse >/dev/null 2>&1
# I3/I4 X+LB / X+RB
: > "$HL"
$VG combo 307 310 300 2600 >/dev/null 2>&1
sleep 1.2
s3=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
x1=$(echo "$s3" | awk '{print $3}' | cut -d, -f1); x2=$(echo "$s3" | awk '{print $5}' | cut -d, -f1)
dx3=0; [ -n "$x1" ] && [ -n "$x2" ] && dx3=$((x2 - x1))
if [ -n "$s3" ] && [ "$dx3" -gt 0 ]; then
  ck RS6-I3 "X+LB → 横向手势向右（dx>0，上一页方向）" "SWIPE=[$s3] dx=+$dx3" PASS
else
  ck RS6-I3 "X+LB → 横向手势向右（dx>0）" "SWIPE=[$s3] dx=${dx3}" FAIL "vgpad combo 307 310 300 2600"
fi
: > "$HL"
$VG combo 307 311 300 2600 >/dev/null 2>&1
sleep 1.2
s4=$(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -1)
y1=$(echo "$s4" | awk '{print $3}' | cut -d, -f1); y2=$(echo "$s4" | awk '{print $5}' | cut -d, -f1)
dx4=0; [ -n "$y1" ] && [ -n "$y2" ] && dx4=$((y2 - y1))
if [ -n "$s4" ] && [ "$dx4" -lt 0 ]; then
  ck RS6-I4 "X+RB → 横向手势向左（dx<0，下一页方向）" "SWIPE=[$s4] dx=${dx4}" PASS
else
  ck RS6-I4 "X+RB → 横向手势向左（dx<0）" "SWIPE=[$s4] dx=${dx4}" FAIL "vgpad combo 307 311 300 2600"
fi
# I5 空闲隐藏原地隐形恢复
startp
cmd statusbar collapse >/dev/null 2>&1
logcat -c
click; P1=$(cxy)
hid0=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
sleep 9.5
hid1=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
logcat -c
click; P2=$(cxy)
corr=$(logcat -d -s DexPad 2>/dev/null | grep -a 'no correction move' | tail -1 | sed 's/^.*DexPad *: //')
dxy=$(awk -v a="$P1" -v b="$P2" 'BEGIN{split(a,p," "); split(b,q," "); if(p[1]==""||q[1]==""){print 999; exit} dx=p[1]-q[1]; dy=p[2]-q[2]; if(dx<0)dx=-dx; if(dy<0)dy=-dy; print (dx>dy)?dx:dy}')
L "  I5: P1=[$P1] P2=[$P2] d=${dxy}px hidden=$hid0->$hid1 corr=[$corr]"
if [ -n "$P1" ] && [ -n "$P2" ] && [ "$dxy" -le 10 ] && echo "$corr" | grep -q 'no correction move'; then
  ck RS6-I5 "空闲隐藏后原地隐形恢复（同点误差 ≤10px 且 no correction move）" "P1=[$P1] P2=[$P2] d=${dxy}px corr=[$corr]" PASS
else
  ck RS6-I5 "空闲隐藏后原地隐形恢复（同点误差 ≤10px 且 no correction move）" "P1=[$P1] P2=[$P2] d=${dxy}px corr=[$corr]" FAIL "click; sleep 9.5; click; logcat -d -s PadProbe"
fi
# I6 SELECT 通知栏
cmd statusbar collapse >/dev/null 2>&1; sleep 0.6
startp
cmd statusbar collapse >/dev/null 2>&1; sleep 0.6
: > "$HL"
$VG key 314 80 0 >/dev/null 2>&1
sleep 2.0
sh1=$(shade)
n6=$(grep -a 'NOTIF' "$HL" 2>/dev/null | tail -2 | tr '\n' '|')
if [ "$sh1" -ge 1 ] && echo "$n6" | grep -q 'NOTIF swipe rc=0'; then
  ck RS6-I6 "SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0" "shade=$sh1 notif=$n6" PASS
else
  ck RS6-I6 "SELECT → 通知栏展开（NotificationShade）+ helper 真实下滑 rc=0" "shade=$sh1 notif=$n6" FAIL "vgpad key 314 80 0; dumpsys window | grep NotificationShade"
fi
cmd statusbar collapse >/dev/null 2>&1

# ---------------------------------------------------------------- RS-7 横屏守护（≤5s 回横屏）
sec "RS-7 横屏守护：外部改竖屏后 ≤5s 自动回横屏"
settings put system user_rotation 0 >/dev/null 2>&1
settings put system accelerometer_rotation 1 >/dev/null 2>&1
it=0; ok=0
while [ $it -lt 24 ]; do
  it=$((it + 1))
  if [ "$(settings get system user_rotation | tr -d '\r')" = "1" ] && [ "$(settings get system accelerometer_rotation | tr -d '\r')" = "0" ]; then
    asz=$(appsize); w=${asz%x*}; h=${asz#*x}
    [ "$w" -gt "$h" ] && { ok=1; break; }
  fi
  sleep 0.25
done
dur=$((it * 250)); asz=$(appsize)
guard=$(logcat -d -s DexPad 2>/dev/null | grep -a 'landscape guardian' | tail -1 | sed 's/^.*DexPad *: //')
L "  guardian: ${dur}ms($it polls) app=$asz user_rotation=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) | $guard"
if [ "$ok" = "1" ] && [ "$dur" -le 5000 ]; then
  ck RS7-GUARD "外部改竖屏后 ≤5s 自动回横屏（settings 回 1/0 且 app 宽>高）" "recovered≈${dur}ms($it×250ms) app=$asz" PASS
else
  ck RS7-GUARD "外部改竖屏后 ≤5s 自动回横屏" "recovered≈${dur}ms ok=$ok app=$asz" FAIL "settings put system user_rotation 0; settings put system accelerometer_rotation 1"
fi

# ---------------------------------------------------------------- RS-8 提速：帧耗时 + 60s 进程级 CPU + 光标查询次数
sec "RS-8 提速与资源（release 字节，60s 空闲）"
am force-stop $PAD >/dev/null 2>&1
cmd statusbar collapse >/dev/null 2>&1
wake
sleep 20
: > "$HL"
PID=$(pidof $PKG)
pt=$(logcat -d -s DexPad 2>/dev/null | grep -a 'perf tick' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')
P0=$(awk '{print $14+$15}' /proc/$PID/stat 2>/dev/null)
CH0=$(awk '{print $16+$17}' /proc/$PID/stat 2>/dev/null)
cpu0=$(awk '{print $14+$15}' /proc/$PID/stat 2>/dev/null)
thr0=$(for t in /proc/$PID/task/*; do awk '{print $14+$15}' "$t/stat" 2>/dev/null; done | awk '{s+=$1} END{print s+0}')
sleep 60
P1=$(awk '{print $14+$15}' /proc/$PID/stat 2>/dev/null)
CH1=$(awk '{print $16+$17}' /proc/$PID/stat 2>/dev/null)
thr1=$(for t in /proc/$PID/task/*; do awk '{print $14+$15}' "$t/stat" 2>/dev/null; done | awk '{s+=$1} END{print s+0}')
cpu=$(awk -v a="$P0" -v b="$P1" 'BEGIN{printf "%.2f", (b-a)/60.0}')
cpu2=$(awk -v a="$thr0" -v b="$thr1" 'BEGIN{printf "%.2f", (b-a)/60.0}')
child=$(awk -v a="$CH0" -v b="$CH1" 'BEGIN{printf "%.2f", (b-a)/60.0}')
cq=$(grep -ac 'CURSORQ' "$HL" 2>/dev/null)
cur=$(grep -ac '^CURSOR ' "$HL" 2>/dev/null)
pt2=$(logcat -d -s DexPad 2>/dev/null | grep -a 'perf tick' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')
L "  60s idle: pid=$PID cpu(proc utime+stime)=${cpu}% thread_sum=${cpu2}% cutime+cstime(delta, should≈0)=${child}% cursorq=$cq cursor=$cur"
L "  perf tick: $pt2"
L "  helper log lines during idle: $(wc -l < "$HL")"
ck RS8-CPU "release 进程级 60s 空闲 CPU（utime+stime）记录并与 v1.65 同口径对比（判定见报告）" "cpu=${cpu}% thread_sum=${cpu2}% child=${child}%" PASS
if [ "$cq" -le 15 ]; then
  ck RS8-Q "60s 空闲内真实光标查询 ≤15 次" "CURSORQ=$cq CURSOR=$cur" PASS
else
  ck RS8-Q "60s 空闲内真实光标查询 ≤15 次" "CURSORQ=$cq CURSOR=$cur" FAIL "grep -c CURSORQ $HL"
fi
if echo "$pt2" | grep -qE 'avg=[0-9]+us'; then
  ck RS8-TICK "引擎帧耗时日志存在（release 字节，avg/max 见 perf tick）" "perf tick: $pt2" PASS
else
  ck RS8-TICK "引擎帧耗时日志存在" "perf tick: ${pt2:-none}" FAIL "logcat -d -s DexPad | grep 'perf tick'"
fi

# ---------------------------------------------------------------- restore
sec "RESTORE 恢复安装状态"
wake; pin
am force-stop $PAD >/dev/null 2>&1
cmd statusbar collapse >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5
L "  restored: helper=$(pidof gpminput) engine=$(pidof $PKG) user_rotation=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) app=$(appsize) wake=$(wf) focus=$(focus)"
L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$RES"
echo "RESULT: $RES ; LOG: $LOG"
[ "$FAIL" -eq 0 ]
