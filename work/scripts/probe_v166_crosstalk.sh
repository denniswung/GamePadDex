#!/system/bin/sh
# probe_v166_crosstalk.sh -- item1：一次滑动手势串扰到两个区域（真机复现 + 量化阈值）
# 用法：adb push work/scripts/probe_v166_crosstalk.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_crosstalk.sh"
# 证据：/data/adb/gpm/helper.log 的 SWIPE 行（真实注入的起止点 + task 边界 + prep）
#       logcat DexPad 的 vswipe（右摇杆 Y）/ swipe vertical=（右摇杆 X 或按钮）
#       logcat PadProbe 的 MOUSE/hover、click-down、TOUCH/swipe（应用真正收到的坐标）
# 判定：一次手势内同时出现 Z 与 V = 串扰；两个起手 y 不同 = 两个区域
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_crosstalk.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running (另一成员在用设备)"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
reset_logs(){ : > /data/adb/gpm/helper.log; logcat -c; }
# 真实注入：每行 = "V|Z display x1,y1->x2,y2 task x1..x2 / y1..y2"
swipes(){ grep -a '^SWIPE ' /data/adb/gpm/helper.log 2>/dev/null | sed -E 's/^SWIPE ([0-9]+) ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+) \(task ([0-9]+)\.\.([0-9]+) \/ ([0-9]+)\.\.([0-9]+)\).*/\1 \2 \3 \4 \5 \6 \7 \8 \9/'; }
classify(){ # stdin: parsed swipe lines -> counts + regions
  awk '{ dir=($5!=$3)?"Z":"V"; if(dir=="Z") z++; else v++;
         if(dir=="Z") zy=zy" "$3; else vy=vy" "$3; } END { printf "Z=%d V=%d Zy=[%s] Vy=[%s]", z+0, v+0, zy, vy }'
}
region_y(){ swipes | awk '{ if($5!=$3) print "Z@"$3; else print "V@"$3 }' | tr '\n' ' '; }
preps(){ grep -ao 'prep=[0-9]*us' /data/adb/gpm/helper.log 2>/dev/null | sed 's/prep=//;s/us//' | tr '\n' ' '; }
vlog(){ logcat -d -s DexPad 2>/dev/null | grep -ac 'vswipe' ; }
hlog(){ logcat -d -s DexPad 2>/dev/null | grep -ac 'swipe vertical=false' ; }
launch(){ logcat -d -s DexPad 2>/dev/null | grep -ac 'launcher foreground -> arrow'; }
run(){ # $1=label $2=wait-after
  sleep "${2:-1}"
  L "  -> $(swipes | classify) prep=[$(preps)] dexpad:vswipe=$(vlog) hswipe=$(hlog) arrow=$(launch)"
  L "     regions: $(region_y)"
  swipes | sed -n '1,6p' | sed 's/^/     SWIPE /' | tee -a "$LOG" >/dev/null
}

wake; sleep 1; startp
L "=== 0. 基线 ==="
L "  screen(app size from engine log): $(logcat -d -s DexPad | grep -a 'cursor centered' | tail -1)"
L "  taskbounds.txt=$(cat /data/adb/gpm/taskbounds.txt 2>/dev/null | tr -d '\n')"
L "  prefs=$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"

L ""
L "=== A. 右摇杆纯纵向 RY=-24000 (0.73) 1200ms（应只有 Z）==="
reset_logs; $VG stick 4 -24000 1200 0 >/dev/null 2>&1; run A 1.2

L ""
L "=== B. 右摇杆纯横向 RX=+24000 (0.73) 1200ms（应只有 V）==="
reset_logs; $VG stick 3 24000 1200 0 >/dev/null 2>&1; run B 1.2

L ""
L "=== C. 斜推 RX=+13000 (0.40) 与 RY=-24000 (0.73) 同一时刻（一次物理推杆的泄漏模型）==="
reset_logs
$VG stick 3 13000 1200 0 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 0 >/dev/null 2>&1 &
wait; run C 1.2

L ""
L "=== D. 斜推 RX=+10000 (0.31) 与 RY=-24000 (0.73)：低于 scroll_deadzone=0.35 ==="
reset_logs
$VG stick 3 10000 1200 0 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 0 >/dev/null 2>&1 &
wait; run D 1.2

L ""
L "=== E. 斜推 RX=+11796 (0.36) 与 RY=-24000 (0.73)：略高于 scroll_deadzone ==="
reset_logs
$VG stick 3 11796 1200 0 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 0 >/dev/null 2>&1 &
wait; run E 1.2

L ""
L "=== F. RB 按住 1500ms（按钮=SCROLL_SWIPE_UP，滑动+滚轮双通道）==="
reset_logs; $VG key 311 1500 800 >/dev/null 2>&1; run F 1.0
L "     WHEEL=$(grep -ac '^WHEEL ' /data/adb/gpm/helper.log 2>/dev/null) wheel_log=$(logcat -d -s DexPad | grep -ac 'wheel ' )"

L ""
L "=== G. RB 按住 + 右摇杆纵向同时（按钮 Z + 摇杆 Z，两个起手区域）==="
reset_logs
$VG key 311 1500 800 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 900 >/dev/null 2>&1 &
wait; run G 1.0

L ""
L "=== H. X+RB（混搭=WHEEL_LEFT 横滑）与右摇杆纵向同时 ==="
reset_logs
$VG combo 307 311 900 800 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 900 >/dev/null 2>&1 &
wait; run H 1.0

L ""
L "=== I. 两个并发 input swipe 本身是否互相干扰（不经过 App）==="
reset_logs; startp
input -d 0 swipe 1280 400 1280 1000 500 >/dev/null 2>&1 &
input -d 0 swipe 300 800 900 800 500 >/dev/null 2>&1 &
wait; sleep 1
L "  PadProbe TOUCH/swipe: $(logcat -d -s PadProbe | grep -c 'TOUCH/swipe')  MOUSE/drag: $(logcat -d -s PadProbe | grep -c 'MOUSE/drag')  click=$(logcat -d -s PadProbe | grep -c 'click-down')"
logcat -d -s PadProbe 2>/dev/null | tail -8 | sed 's/^/     /' | tee -a "$LOG"
input -d 0 swipe 1280 400 1280 1000 500 >/dev/null 2>&1; L "  single swipe rc=$?"

L ""
L "=== J. task 边界缓存污染：把 /data/adb/gpm/taskbounds.txt 写成 0 0 1200 800 后立刻纵向滑动 ==="
reset_logs; startp
echo "0 0 1200 800" > /data/adb/gpm/taskbounds.txt
$VG stick 4 -24000 900 0 >/dev/null 2>&1; sleep 0.6
L "  污染后立刻: $(swipes | head -2 | tr '\n' '|')  cache=$(cat /data/adb/gpm/taskbounds.txt)"
sleep 3
L "  3s 后缓存自动刷新: cache=$(cat /data/adb/gpm/taskbounds.txt)"
reset_logs
$VG stick 4 -24000 900 0 >/dev/null 2>&1; sleep 0.6
L "  刷新后: $(swipes | head -2 | tr '\n' '|')"

L ""
L "=== K. MT slot 残留假设验证：滚动在飞行中点击（uinput 触摸 vs injected swipe）==="
reset_logs
$VG stick 4 -24000 1200 0 >/dev/null 2>&1 &
sleep 0.5; $VG key 304 100 0 >/dev/null 2>&1 &
wait; sleep 0.8
L "  click-down=$(logcat -d -s PadProbe | grep -c 'MOUSE/click-down') TOUCH/swipe=$(logcat -d -s PadProbe | grep -c 'TOUCH/swipe') helper:TOUCH=$(grep -ac '^TOUCH ' /data/adb/gpm/helper.log 2>/dev/null)"
L "  PadProbe tail: $(logcat -d -s PadProbe | tail -4 | tr '\n' '|')"

L ""
L "=== L. 双指缩放在飞行中单指点击：MT slot 0 是否被 pinch 的 slot 复用（残留假设）==="
reset_logs
$VG stick 9 255 900 0 >/dev/null 2>&1 &   # ABS_GAS -> AXIS_GAS -> onTrigger("lt") = ZOOM_OUT
sleep 0.4; $VG key 304 100 0 >/dev/null 2>&1 &
wait; sleep 0.8
L "  helper PINCH=$(grep -ac '^PINCH' /data/adb/gpm/helper.log 2>/dev/null) TOUCH=$(grep -ac '^TOUCH ' /data/adb/gpm/helper.log 2>/dev/null)"
L "  helper lines: $(grep -aE '^(PINCH|TOUCH)' /data/adb/gpm/helper.log 2>/dev/null | head -4 | tr '\n' '|')"
L "  PadProbe: click-down=$(logcat -d -s PadProbe | grep -c 'MOUSE/click-down') TOUCH/swipe=$(logcat -d -s PadProbe | grep -c 'TOUCH/swipe')"

sleep 1
L ""
L "DONE $(getprop ro.serialno)"
