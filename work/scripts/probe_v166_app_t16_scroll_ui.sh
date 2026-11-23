#!/system/bin/sh
# t16 独立滚动测量：uiautomator dump 前后对比（不依赖 auto_suite）
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_t16_scroll.log
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
dump(){ uiautomator dump /sdcard/t16ui.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/t16ui.xml > /sdcard/t16ui.lines; }
py(){ grep -m1 'text="第 1 页"' /sdcard/t16ui.lines 2>/dev/null | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\].*/\2/p'; }
hs(){ sed -n 's/.*text="第 1 页".*bounds="\[\([0-9]*\),[0-9]*\]\[\([0-9]*\),[0-9]*\]".*/\1 \2/p' /sdcard/t16ui.lines 2>/dev/null | head -1 | awk '{ d=$2-$1; if(d>0 && d<600) print 600-d; else print 0 }'; }
sv(){ grep -o 'scrollable="true"' /sdcard/t16ui.lines 2>/dev/null | wc -l; }
wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse >/dev/null 2>&1
dump
P0=$(py); H0=$(hs); Y0=$(grep -o 'bounds="\[[0-9]*,\([0-9]*\)\]' /sdcard/t16ui.lines | head -3 | tr '\n' ' ')
L "== start: PY=$P0 HS=$H0 scrollable=$(sv) first_bounds_y=[$Y0]"
echo "--- vertical stick 1.5s ---" >> "$LOG"
$VG stick 4 -24000 1500 0 >/dev/null 2>&1
sleep 1.5
dump
P1=$(py); H1=$(hs)
L "   after V: PY=$P1 HS=$H1 dPY=$((P0-P1)) new_first_bounds=$(grep -o 'bounds="\[[0-9]*,\([0-9]*\)\]' /sdcard/t16ui.lines | head -3 | tr '\n' ' ')"
echo "--- horizontal stick 1.5s ---" >> "$LOG"
$VG stick 3 24000 1500 0 >/dev/null 2>&1
sleep 1.5
dump
P2=$(py); H2=$(hs)
L "   after H: PY=$P2 HS=$H2 dHS=$((H2-H1))"
L "   page1: $(grep -m1 'text="第 1 页"' /sdcard/t16ui.lines | grep -o 'bounds="[^"]*"')"
L "   page2: $(grep -m1 'text="第 2 页"' /sdcard/t16ui.lines | grep -o 'bounds="[^"]*"')"
L DONE
