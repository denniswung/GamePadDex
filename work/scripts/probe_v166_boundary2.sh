#!/system/bin/sh
# probe_v166_boundary2.sh -- item3 量化「夹住带」：真实光标贴边后，继续推杆的无效段（估算 vs 真实）
# 用法：adb push work/scripts/probe_v166_boundary2.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_boundary2.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_boundary2.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
click(){ $VG key 304 80 0 >/dev/null 2>&1; sleep 0.4; }
push(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.3; }
clickxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
est(){ logcat -d -s DexPad 2>/dev/null | grep -a 'ptr move' | tail -1 | sed -n 's/.*at \([0-9-]*\),\([0-9-]*\).*/\1,\2/p'; }
shot(){ logcat -c; push "$1" "$2" "$3"; click; L "  $4 actual=$(clickxy) est=$(est)"; }

wake; startp; cmd statusbar collapse >/dev/null 2>&1
L "=== 左边界夹住带：L3 后向左推，真实贴住 x=0 后继续推 5 段 200ms ==="
l3; L "  L3 done (real 目标 1280,800 但 gain 偏差 -> 1925,1200)"
shot 0 -30000 300 "L-push1"
shot 0 -30000 300 "L-push2"
shot 0 -30000 200 "L-dead1"
shot 0 -30000 200 "L-dead2"
shot 0 -30000 200 "L-dead3"
shot 0 -30000 200 "L-dead4"
shot 0 -30000 200 "L-dead5"
L "  (dead 段里 actual 不变、est 继续减小 = 光标贴边后被夹住，估算与真实分离)"

L ""
L "=== 反推：此时向左推的真实/估算比 = 3.25/2.16 = 1.50（见 gain 探针）==="
L "DONE $(getprop ro.serialno)"
