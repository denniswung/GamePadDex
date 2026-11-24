#!/system/bin/sh
# t37 H2 专项：scroll_speed 三档 + 改 pref 不重启 + 按压中快照（修正版）
VG=/data/local/tmp/vgpad
PKG=com.dennis.dexpad
OUT=/data/local/tmp/h2_t37.log
RAW=/data/local/tmp/drag_raw
mkdir -p "$RAW"; : > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
set_speed(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref scroll_speed --ei ival "$1" >/dev/null 2>&1; sleep 0.6; }
starts(){ am force-stop com.dennis.padtest >/dev/null 2>&1; am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.3; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 0.8; }
drag_start(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag start' | tail -1 | sed 's/^.*DexPad *: //'; }
drag_end(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //'; }
total(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1 | sed -n 's/.*total=\([0-9]*\)px.*/\1/p'; }
mult(){ logcat -d -s DexPad 2>/dev/null | grep -a 'drag start' | tail -1 | sed -n 's/.*mult=\([0-9.]*\).*/\1/p'; }

eng0=$(pidof $PKG)
t2=""; t4=""; t7=""
for sp in 2 4 7; do
  starts; l3; logcat -c
  set_speed $sp
  $VG key 311 1500 400 >/dev/null 2>&1; sleep 1.0
  tt=$(total); [ -z "$tt" ] && tt=0
  L "speed=$sp: total=${tt}px mult=$(mult) start=[$(drag_start)]"
  case $sp in 2) t2=$tt;; 4) t4=$tt;; 7) t7=$tt;; esac
done
L "三档: $t2 / $t4 / $t7 ; engine pid $eng0 -> $(pidof $PKG)"
if [ "$t2" -lt "$t4" ] && [ "$t4" -lt "$t7" ] && [ "$t4" -ge 1200 ] && [ "$t4" -le 2200 ]; then
  L "[H2-SPEED] PASS | 三档单调且默认档∈[1200,2200] | $t2/$t4/$t7"
else L "[H2-SPEED] FAIL | $t2/$t4/$t7"; fi
[ "$eng0" = "$(pidof $PKG)" ] && L "[H2-NORESTART] PASS | pid=$eng0" || L "[H2-NORESTART] FAIL | $eng0 -> $(pidof $PKG)"
# 按压中改 pref：按住 3000ms，1.7s 时改 10（drag start 约在按压后 1.0~1.2s）
starts; l3; logcat -c; set_speed 4
$VG key 311 3000 400 >/dev/null 2>&1 &
sleep 1.7
set_speed 10
wait
sleep 1.0
tm=$(total); mm=$(mult); ds=$(drag_start)
L "按压中改 pref(4→10, @1.7s): total=${tm:-na} mult=${mm:-na} start=[$ds]"
if [ -n "$mm" ] && [ "${mm%%.*}" = "1" ] && [ "${tm:-0}" -ge 2150 ] && [ "${tm:-0}" -le 2300 ]; then
  L "[H2-NOSWITCH] PASS | 起手 mult=1.0、总位移 ${tm}px（上限 2200，未随 10 档变大）"
else L "[H2-NOSWITCH] FAIL | total=${tm:-na} mult=${mm:-na}"; fi
set_speed 4
echo "RESULT: $OUT"
