#!/system/bin/sh
# v166_hash_recheck.sh -- t12 最终哈希复验（t10/t11 之后，助手 6076b63b…）
#
# 覆盖：
#   S1 `?` 自检（指针可见）   : 13 项 CAP 全 1（CAP devices 为数量，允许 0）、ERR count=0、INFO pointer device=on
#   S2 `?` 自检（空闲隐藏后） : CAP 行与 S1 逐字相同、ERR count=0、INFO pointer device=off（t11 修复点）
#   C1 串行手势队列：6 次交替推杆，helper.log 无两条并存 SWIPE（overlaps=0、starts==dones）
#   C2 Y+上 / Y+下：前台组件（piliplus / aweme）+ helper OPEN_APP via 组件（fallback=0、monkey=0）
#   C3 X 双击（400ms）→ 前台 RecentsActivity
#   C4 SELECT → NotificationShade + NOTIF swipe rc=0
#   C5 L3 居中：PadProbe 点击落点 vs 横屏中心 ≤80px，且是鼠标点击（非 DPAD_CENTER）
#
# 用法：adb push work/scripts/v166_hash_recheck.sh /data/local/tmp/
#       adb -s 192.168.10.36:6666 shell "sh /data/local/tmp/v166_hash_recheck.sh"
# 输出：/data/local/tmp/v166_hash_recheck.log（PASS/FAIL 行 + 原始证据摘录）
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
LOG=/data/local/tmp/v166_hash_recheck.log

PASS=0
FAIL=0
FAILED=""
: > "$LOG"

L() { echo "$@" | tee -a "$LOG"; }
sec() { echo "" | tee -a "$LOG"; echo "===== $* =====" | tee -a "$LOG"; }
ck() { # id 阈值 实测 PASS|FAIL
  local id="$1" thr="$2" meas="$3" verd="$4"
  if [ "$verd" = "PASS" ]; then PASS=$((PASS + 1)); printf '[%s] PASS | 阈值: %s | 实测: %s\n' "$id" "$thr" "$meas" | tee -a "$LOG"
  else FAIL=$((FAIL + 1)); FAILED="$FAILED $id"; printf '[%s] FAIL | 阈值: %s | 实测: %s\n' "$id" "$thr" "$meas" | tee -a "$LOG"; fi
}

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin() { settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
startp() { am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.0; }
l3() { $VG key 317 100 800 >/dev/null 2>&1; sleep 1.1; }
click() { $VG key 304 60 0 >/dev/null 2>&1; sleep 0.45; }
topact() { dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
shade() { dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*NotificationShade'; }
cxy() { logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
hcmd() { am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
last_selftest() { # 取 helper.log 里最后一段 SELFTEST begin..end
  awk '/^SELFTEST begin/{buf=""; inb=1} inb{buf=buf"\n"$0} /^SELFTEST end/{if(inb){last=buf; inb=0}} END{print last}' "$HL" 2>/dev/null
}
cap_bad() { # 非 1 的 CAP（CAP devices 是数量，不算）
  echo "$1" | grep -a '^CAP ' | grep -av '^CAP devices ' | awk '{ if ($3 != 1) print $0 }' | tr '\n' ';'
}
cap_lines() { echo "$1" | grep -a '^CAP ' | tr '\n' ';'; }
info_pointer() { echo "$1" | grep -a '^INFO pointer device=' | tail -1 | sed 's/.*device=//'; }
err_cnt() { echo "$1" | grep -ac '^ERR'; }

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
L "v166_hash_recheck start=$(date)"
L "  helper_sha=$(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
L "  module_sha=$(sha256sum /data/adb/modules/gpm_dex/gpminput | cut -d' ' -f1)"
L "  helper_pid=$(pidof gpminput) engine_pid=$(pidof $PKG)"

wake
pin
startp
cmd statusbar collapse >/dev/null 2>&1

# ---------------- S1 自检（指针可见）
sec "S1 \`?\` 自检：指针可见"
l3                       # 真实输入：显示指针并刷新 lastUserInputAt
hcmd "j"                 # 确保指针设备存在
sleep 0.8
hcmd "?"
sleep 2.2
S1=$(last_selftest)
P1=$(info_pointer "$S1")
BAD1=$(cap_bad "$S1")
E1=$(err_cnt "$S1")
L "  CAP: $(cap_lines "$S1")"
L "  INFO pointer=$P1 ERR=$E1"
if [ "$(echo "$S1" | grep -ac '^CAP ')" -ge 13 ] && [ -z "$BAD1" ] && [ "$E1" = "0" ] && [ "$P1" = "on" ]; then
  ck S1 "13 项 CAP 全 1（CAP devices 数量除外）、ERR=0、pointer device=on" "CAP n=$(echo "$S1" | grep -ac '^CAP ') bad=[$BAD1] ERR=$E1 pointer=$P1" PASS
else
  ck S1 "13 项 CAP 全 1（CAP devices 数量除外）、ERR=0、pointer device=on" "CAP n=$(echo "$S1" | grep -ac '^CAP ') bad=[$BAD1] ERR=$E1 pointer=$P1" FAIL
fi

# ---------------- S2 自检（空闲隐藏后）
sec "S2 \`?\` 自检：空闲隐藏后（>idle_hide 8s）"
sleep 10                 # 引擎按 idle_hide_sec=8 销毁指针设备
hcmd "?"
sleep 2.2
S2=$(last_selftest)
P2=$(info_pointer "$S2")
BAD2=$(cap_bad "$S2")
E2=$(err_cnt "$S2")
CAP1=$(cap_lines "$S1" | grep -av '^CAP devices ' )
CAP2=$(cap_lines "$S2" | grep -av '^CAP devices ' )
L "  CAP: $(cap_lines "$S2")"
L "  INFO pointer=$P2 ERR=$E2"
L "  CAP 行与 S1 一致=$([ "$CAP1" = "$CAP2" ] && echo yes || echo no)"
if [ "$(echo "$S2" | grep -ac '^CAP ')" -ge 13 ] && [ -z "$BAD2" ] && [ "$E2" = "0" ] && [ "$P2" = "off" ] && [ "$CAP1" = "$CAP2" ]; then
  ck S2 "指针隐藏后 CAP 与 S1 逐字相同全 1、ERR=0、pointer device=off" "CAP n=$(echo "$S2" | grep -ac '^CAP ') bad=[$BAD2] ERR=$E2 pointer=$P2 same=yes" PASS
else
  ck S2 "指针隐藏后 CAP 与 S1 逐字相同全 1、ERR=0、pointer device=off" "CAP n=$(echo "$S2" | grep -ac '^CAP ') bad=[$BAD2] ERR=$E2 pointer=$P2" FAIL
fi

# ---------------- C1 串行手势队列
sec "C1 串行手势队列（6 次交替推杆）"
: > "$HL"
i=0
while [ $i -lt 3 ]; do
  i=$((i + 1))
  $VG stick 4 24000 1200 >/dev/null 2>&1
  sleep 0.4
  $VG stick 3 24000 1200 >/dev/null 2>&1
  sleep 0.4
done
sleep 1.0
SER=$(awk '
  /^SWIPE [0-9]/ { if (open==1) ov++; open=1; st++ }
  /^SWIPE_DONE/ { if (open==1) { open=0; dn++ } else orphan++ }
  /^SWIPE_DROP/ { dr++ }
  /^SWIPE_QUEUED/ { q++ }
  END{ printf "starts=%d dones=%d overlaps=%d orphan=%d drops=%d queued=%d inflight=%d", st+0, dn+0, ov+0, orphan+0, dr+0, q+0, open+0 }' "$HL")
L "  $SER"
OV=$(echo "$SER" | sed -n 's/.*overlaps=\([0-9]*\).*/\1/p')
SN=$(echo "$SER" | sed -n 's/.*starts=\([0-9]*\).*/\1/p')
DN=$(echo "$SER" | sed -n 's/.*dones=\([0-9]*\).*/\1/p')
if [ "$OV" = "0" ] && [ "$SN" -ge 6 ] && [ "$SN" = "$DN" ]; then
  ck C1 "overlaps=0 且 starts==dones≥6（任意时刻 ≤1 条 input swipe 在飞）" "$SER" PASS
else
  ck C1 "overlaps=0 且 starts==dones≥6（任意时刻 ≤1 条 input swipe 在飞）" "$SER" FAIL
fi

# ---------------- C2 Y+上 / Y+下
sec "C2 Y+上 → PiliPlus、Y+下 → 抖音"
startp
: > "$HL"
$VG keyvhat 308 -1 500 2600 >/dev/null 2>&1
sleep 2.5
T1=$(topact); O1=$(grep -a 'OPEN_APP com.example.piliplus' "$HL" 2>/dev/null | tail -1); FB1=$(grep -ac 'fallback=pkg' "$HL"); MK1=$(grep -ac 'monkey' "$HL")
L "  Y+up top=$T1 [$O1]"
case "$T1" in *piliplus*) H1=1 ;; *) H1=0 ;; esac
if [ "$H1" = "1" ] && [ "$FB1" = "0" ] && [ "$MK1" = "0" ] && echo "$O1" | grep -q 'via com.example.piliplus/'; then
  ck C2A "Y+上 → 前台 piliplus 且组件解析启动（fallback=0 monkey=0）" "top=$T1 | $O1" PASS
else
  ck C2A "Y+上 → 前台 piliplus 且组件解析启动（fallback=0 monkey=0）" "top=$T1 fb=$FB1 mk=$MK1 | $O1" FAIL
fi
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5
: > "$HL"
$VG keyvhat 308 1 500 2600 >/dev/null 2>&1
sleep 2.5
T2=$(topact); O2=$(grep -a 'OPEN_APP com.ss.android.ugc.aweme' "$HL" 2>/dev/null | tail -1); FB2=$(grep -ac 'fallback=pkg' "$HL"); MK2=$(grep -ac 'monkey' "$HL")
L "  Y+down top=$T2 [$O2]"
case "$T2" in *aweme*) H2=1 ;; *) H2=0 ;; esac
if [ "$H2" = "1" ] && [ "$FB2" = "0" ] && [ "$MK2" = "0" ] && echo "$O2" | grep -q 'via com.ss.android.ugc.aweme/'; then
  ck C2B "Y+下 → 前台抖音 且组件解析启动（fallback=0 monkey=0）" "top=$T2 | $O2" PASS
else
  ck C2B "Y+下 → 前台抖音 且组件解析启动（fallback=0 monkey=0）" "top=$T2 fb=$FB2 mk=$MK2 | $O2" FAIL
fi

# ---------------- C3 X 双击
sec "C3 X 双击（400ms 窗口）→ 多任务"
startp
logcat -c
$VG double 307 60 200 2600 >/dev/null 2>&1
sleep 1.2
T3=$(topact)
L "  top=$T3"
case "$T3" in *RecentsActivity*) H3=1 ;; *) H3=0 ;; esac
if [ "$H3" = "1" ]; then
  ck C3 "X 双击 → 前台 RecentsActivity" "top=$T3" PASS
else
  ck C3 "X 双击 → 前台 RecentsActivity" "top=$T3" FAIL
fi

# ---------------- C4 SELECT
sec "C4 SELECT → 通知栏（真实下滑手势）"
cmd statusbar collapse >/dev/null 2>&1
sleep 0.6
startp
cmd statusbar collapse >/dev/null 2>&1
sleep 0.6
: > "$HL"
$VG key 314 80 0 >/dev/null 2>&1
sleep 1.8
SH=$(shade); NF=$(grep -a 'NOTIF' "$HL" 2>/dev/null | tr '\n' '|')
L "  shade=$SH notif=[$NF]"
if [ "$SH" -ge 1 ] && echo "$NF" | grep -q 'NOTIF swipe rc=0'; then
  ck C4 "NotificationShade 前台 + helper NOTIF swipe rc=0" "shade=$SH [$NF]" PASS
else
  ck C4 "NotificationShade 前台 + helper NOTIF swipe rc=0" "shade=$SH [$NF]" FAIL
fi
cmd statusbar collapse >/dev/null 2>&1
sleep 0.5

# ---------------- C5 L3 居中
sec "C5 L3 居中（Landscape 中心 1280,800）"
startp
logcat -c
l3
click
A=$(cxy)
MC=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down')
KE=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER')
E=$(awk -v a="$A" 'BEGIN{ if(a==""){print 999;exit} split(a,p," "); dx=p[1]-1280; dy=p[2]-800; if(dx<0)dx=-dx; if(dy<0)dy=-dy; print (dx>dy)?dx:dy }')
L "  click=[$A] err=${E}px mouse_click=$MC key_enter=$KE"
if [ -n "$A" ] && [ "$E" -le 80 ] && [ "$MC" -ge 1 ] && [ "$KE" -eq 0 ]; then
  ck C5 "L3 落点误差 ≤80px 且为鼠标点击（mouse_click≥1、key_enter=0）" "click=[$A] err=${E}px" PASS
else
  ck C5 "L3 落点误差 ≤80px 且为鼠标点击（mouse_click≥1、key_enter=0）" "click=[$A] err=${E}px mc=$MC ke=$KE" FAIL
fi

# ---------------- 收尾
sec "R 恢复"
wake
pin
startp
cmd statusbar collapse >/dev/null 2>&1
l3
click
L "  helper=$(pidof gpminput) engine=$(pidof $PKG) wf=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*=//') top=$(topact) app=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)"
echo "" | tee -a "$LOG"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$LOG"
[ -n "$FAILED" ] && echo "FAILED_IDS:$FAILED" | tee -a "$LOG"
if [ "$FAIL" -eq 0 ]; then exit 0; else exit 1; fi
