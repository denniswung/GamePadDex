import io

p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v21_inject.sh"
s = io.open(p, encoding="utf-8").read()
start = s.index("# edge slowdown: vertical travel at the centre vs near the top edge")
end = s.index("# horizontal inertia")
new = '''# edge slowdown: same stick input, virtual pointer at the centre vs at the edge
v2 --ei edge_slow 50; sleep 0.3
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
py() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at ([0-9.]*, //;s/)//'; }
inj_pos() { am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind pos --ef x "$1" --ef y "$2" >/dev/null 2>&1; }
stick_down_300() {
    i=0
    while [ $i -lt 3 ]; do
        am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 1 --ef rx 0 --ef ry 0 >/dev/null 2>&1
        sleep 0.1
        i=$((i+1))
    done
    inj_stick 0 0 0 0
}
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
inj_pos 1280 800
C0=$(py); stick_down_300; sleep 0.3; C1=$(py)
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
inj_pos 10 10
E0=$(py); stick_down_300; sleep 0.3; E1=$(py)
CD=$(awk -v a="$C0" -v b="$C1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
ED=$(awk -v a="$E0" -v b="$E1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
echo "edge samples: centre $C0->$C1 ($CD px), edge $E0->$E1 ($ED px)"
if [ -n "$CD" ] && [ -n "$ED" ] && [ "$CD" -gt 0 ] && log | grep -q "edge slow" && [ "$ED" -lt $((CD * 90 / 100)) ]; then
    ok "edge slowdown ($ED px < 90% of $CD px)"
else
    bad "edge slowdown (centre=$CD edge=$ED log=$(log | grep -c 'edge slow'))"
fi

'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("edge via pos injection")
