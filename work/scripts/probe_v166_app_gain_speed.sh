#!/system/bin/sh
# L3 在 pointer_speed=0/3/7 三档下的闭环精度（每档连续 3 次，阈值 ≤80px）
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_gain_speed.log
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
cxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
l3(){ $VG key 317 100 1400 >/dev/null 2>&1; sleep 1.4; }
click(){ $VG key 304 60 1000 >/dev/null 2>&1; sleep 0.5; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
cmd statusbar collapse >/dev/null 2>&1
OLD=$(settings get system pointer_speed)
L "=== pointer_speed 切换下的 L3 居中（原值=$OLD）==="
for ps in 0 3 7; do
  settings put system pointer_speed "$ps"
  sleep 2
  for i in 1 2 3; do
    logcat -c
    l3
    click
    A=$(cxy); AX=${A% *}; AY=${A#* }
    CE=$(logcat -d -s DexPad | grep -a 'CENTER_OK' | tail -1 | sed 's/^.*DexPad *: //')
    MG=$(logcat -d -s DexPad | grep -a 'moveGain calibrated' | tail -1 | sed 's/^.*DexPad *: //')
    L "  ps=$ps run$i click=[$A] err=$(( ${AX:-0} - 1280 )),$(( ${AY:-0} - 800 ))"
    L "       $CE"
    L "       $MG"
  done
done
settings put system pointer_speed "$OLD"
L "restored pointer_speed=$(settings get system pointer_speed)"
L DONE
