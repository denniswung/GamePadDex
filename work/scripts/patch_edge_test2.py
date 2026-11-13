import io

p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v21_inject.sh"
s = io.open(p, encoding="utf-8").read()
start = s.index("# edge slowdown: travel at centre vs at the left edge")
end = s.index("# horizontal inertia")
new = '''# edge slowdown: vertical travel at the centre vs near the top edge
v2 --ei edge_slow 50; sleep 0.3
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
py() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at ([0-9.]*, //;s/)//'; }
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
C0=$(py)
inj_stick 0 1 0 0; sleep 0.35; inj_stick 0 0 0 0; sleep 0.25
C1=$(py)
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
inj_stick 0 -1 0 0; sleep 1.5; inj_stick 0 0 0 0; sleep 0.25   # to the top edge
E0=$(py)
inj_stick 0 1 0 0; sleep 0.35; inj_stick 0 0 0 0; sleep 0.25
E1=$(py)
CD=$(awk -v a="$C0" -v b="$C1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
ED=$(awk -v a="$E0" -v b="$E1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
echo "edge samples: centre $C0->$C1 ($CD px), edge $E0->$E1 ($ED px)"
if [ -n "$CD" ] && [ -n "$ED" ] && [ "$CD" -gt 0 ] && [ "$ED" -lt $((CD * 85 / 100)) ]; then
    ok "edge slowdown ($ED < 85% of $CD)"
else
    bad "edge slowdown (centre=$CD edge=$ED)"
fi

'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("edge y-test")
