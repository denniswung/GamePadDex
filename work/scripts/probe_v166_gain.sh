#!/system/bin/sh
# probe_v166_gain.sh -- item2/3 根因：helper 的 REL->px 真实增益 G vs App 的 center_gain（默认 2.16）
# 用法：adb push work/scripts/probe_v166_gain.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_gain.sh"
# 原理：O/center 命令 = 40 步有界推到 (0,0)（必撞左上角，与起点无关）+ 一步 (w/2/g, h/2/g)
#       => 实际落点 = (w/2/g)*G。所以 G = actual_x * g / (w/2)。
# 副作用（必须恢复）：改 center_gain + 重启引擎；改 pointer_speed；最后恢复原 prefs 与 rotation。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_gain.log
PREFS=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
BAK=/data/local/tmp/v166_prefs_backup.xml

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
click(){ $VG key 304 80 0 >/dev/null 2>&1; sleep 0.5; }
clickxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
setsize(){ # w h
  sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p' 2>/dev/null
}
restart_app(){ am force-stop $PKG >/dev/null 2>&1; sleep 0.6; am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 6; }
set_pref_int(){ # $1 key $2 value : 改 XML（App 必须先停）
  am force-stop $PKG >/dev/null 2>&1; sleep 0.5
  awk -v k="$1" -v v="$2" '
    BEGIN{done=0}
    $0 ~ ("name=\"" k "\"") { next }
    /<\/map>/ && !done { printf "    <int name=\"%s\" value=\"%s\" />\n", k, v; done=1 }
    {print}
  ' "$PREFS" > "$PREFS.new" && cat "$PREFS.new" > "$PREFS" && rm -f "$PREFS.new"
  chown $(stat -c %u:%g "$PREFS") "$PREFS" 2>/dev/null
  restart_app
}

wake; sleep 1; startp
[ -f "$PREFS" ] && cp "$PREFS" "$BAK"
ORIG_ROT=$(settings get system user_rotation)
ORIG_PS=$(settings get system pointer_speed)
L "=== 0. 原始状态 ==="
L "  prefs_backup=$BAK"
L "  prefs=$(cat "$PREFS" 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
L "  user_rotation=$ORIG_ROT pointer_speed=$ORIG_PS forced=$(settings get global display_size_forced)"

L ""
L "=== 1. forceLandscape 的实际效果：user_rotation=0 + 重启引擎 ==="
settings put system user_rotation 0 >/dev/null 2>&1; sleep 2
L "  重启前: user_rotation=$(settings get system user_rotation) size=$(dumpsys window displays | grep -m1 'mDisplayId=0 ' -A3 | grep -m1 'init=' | sed 's/.*cur=\([0-9x]*\).*/cur=\1/')"
restart_app
L "  重启后: user_rotation=$(settings get system user_rotation) helper_log_rotation=$(grep -a '^ROTATION' /data/adb/gpm/helper.log | tail -1)"
L "  engine: $(logcat -d -s DexPad | grep -aE 'helper ready|center|pointer' | tail -3 | tr '\n' '|')"

L ""
L "=== 2. 增益扫描：center_gain -> 实际落点 -> 反推真实增益 G ==="
for pair in 400:4.00 325:3.25 216:2.16; do
  CG=${pair%%:*}; G=${pair#*:}
  set_pref_int center_gain "$CG"
  startp
  S=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p')
  W=${S% *}; H=${S#* }; [ -z "$W" ] && W=2560; [ -z "$H" ] && H=1600
  logcat -c; l3; click
  A=$(clickxy); AX=${A% *}; AY=${A#* }
  IM=$(awk -v ax="$AX" -v g="$G" -v w="$W" 'BEGIN{ if(ax<=0||w<=0) print "n/a"; else printf "%.3f", ax*g/(w/2) }')
  L "  gain=$G (center_gain=$CG) size=${W}x${H} actual=$AX,$AY err_vs_center=$((AX-W/2)),$((AY-H/2)) implied_G=$IM"
  L "     center_log=$(logcat -d -s DexPad | grep -a 'cursor centered' | tail -1 | sed 's/^.*DexPad *: //') | helper=$(grep -a '^CENTER' /data/adb/gpm/helper.log | tail -1)"
done

L ""
L "=== 3. 真实增益是否随 pointer_speed 变（g=4.00，避免裁边）==="
set_pref_int center_gain 400
startp
for ps in 0 3 7; do
  settings put system pointer_speed "$ps" >/dev/null 2>&1; sleep 1.5
  logcat -c; l3; click
  A=$(clickxy); AX=${A% *}; AY=${A#* }
  IM=$(awk -v ax="$AX" -v w=2560 'BEGIN{ if(ax<=0) print "n/a"; else printf "%.3f", ax*4.00/(w/2) }')
  L "  pointer_speed=$ps -> actual=$AX,$AY implied_G=$IM"
done
settings put system pointer_speed "$ORIG_PS" >/dev/null 2>&1

L ""
L "=== 4. 恢复原始 prefs + 引擎 ==="
am force-stop $PKG >/dev/null 2>&1; sleep 0.5
[ -f "$BAK" ] && cat "$BAK" > "$PREFS" && chown $(stat -c %u:%g "$PREFS") "$PREFS" 2>/dev/null
restart_app
settings put system user_rotation 1 >/dev/null 2>&1; sleep 1
L "  恢复后 prefs=$(cat "$PREFS" 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
L "  rotation=$(settings get system user_rotation) pointer_speed=$(settings get system pointer_speed) dexpad_pid=$(pidof $PKG) helper=$(pidof gpminput)"
L "DONE $(getprop ro.serialno)"
