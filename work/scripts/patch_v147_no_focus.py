import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_checklist.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index("# ---- S-04/S-05 控件级焦点 ----")
end = s.index("# ---- S-08 input latency")
new = '''# ---- S-04/S-05 swipe geometry: clamped to the foreground task ----
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
L=$(hcount)
$VG stick 4 20000 1000 2500 >/dev/null 2>&1
sleep 1.2
SW=$(hl "$L" | grep -m1 'SWIPE ')
echo "      $SW"
if echo "$SW" | grep -q '(task '; then
    # start and end must stay inside the task rectangle
    TB=$(echo "$SW" | sed -n 's/.*(task \\([0-9]*\\)\\.\\.\\([0-9]*\\) \\/ \\([0-9]*\\)\\.\\.\\([0-9]*\\)).*/\\1 \\2 \\3 \\4/p')
    XY=$(echo "$SW" | sed -n 's/SWIPE [0-9]* \\([0-9]*\\),\\([0-9]*\\) -> \\([0-9]*\\),\\([0-9]*\\).*/\\1 \\2 \\3 \\4/p')
    set -- $TB; TX1=$1; TX2=$2; TY1=$3; TY2=$4
    set -- $XY; SX1=$1; SY1=$2; SX2=$3; SY2=$4
    if [ "$SX1" -ge "$TX1" ] && [ "$SX1" -le "$TX2" ] && [ "$SY1" -ge "$TY1" ] && [ "$SY1" -le "$TY2" ] &&
       [ "$SX2" -ge "$TX1" ] && [ "$SX2" -le "$TX2" ] && [ "$SY2" -ge "$TY1" ] && [ "$SY2" -le "$TY2" ]; then
        ok "S-04 swipe stays inside the task ($SX1,$SY1 -> $SX2,$SY2 in $TX1..$TX2 / $TY1..$TY2)"
    else
        bad "S-04 swipe outside task ($SW)"
    fi
else
    bad "S-04 no task-bounds swipe ($SW)"
fi

# ---- S-05 five consecutive scrolls still produce swipes (no stall) ----
L=$(hcount)
for i in 1 2 3 4 5; do
    $VG stick 4 20000 600 2500 >/dev/null 2>&1
    sleep 0.7
done
N=$(hl "$L" | grep -c 'SWIPE')
[ "$N" -ge 3 ] && ok "S-05 continuous scroll output ($N swipes)" || bad "S-05 scroll output ($N)"

'''
s = s[:start] + new + s[end:]

# S-06 (wheel mode) stays: wheel output instead of swipe
old6 = s[s.index("# ---- S-06 focus off -> task bounds ----"):s.index("# ---- S-07 wheel mode anchors")]
new6 = '''# ---- S-06 wheel mode emits wheel steps, not swipes ----
setbool v_touch_scroll false
sleep 0.6
L=$(hcount)
$VG stick 4 20000 800 2500 >/dev/null 2>&1
sleep 1.0
W=$(hl "$L" | grep -c 'WHEEL')
S=$(hl "$L" | grep -c 'SWIPE')
[ "$W" -ge 1 ] && [ "$S" -eq 0 ] && ok "S-06 wheel backend (wheel=$W swipe=$S)" || bad "S-06 wheel backend (wheel=$W swipe=$S)"
setbool v_touch_scroll true
sleep 0.4

'''
s = s.replace(old6, new6)

# drop the old anchor test entirely
start = s.index("# ---- S-07 wheel mode anchors")
end = s.index("# ---- S-08 input latency")
s = s[:start] + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
