import io

p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v21_inject.sh"
s = io.open(p, encoding="utf-8").read()
start = s.index("# edge slowdown: travel at centre vs at the left edge")
end = s.index("# horizontal inertia")
new = '''# edge slowdown: travel at centre vs at the left edge
v2 --ei edge_slow 40; sleep 0.3
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.0
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.3
px() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at (//;s/,.*//'; }
C0=$(px)
inj_stick 1 0 0 0; sleep 0.35; inj_stick 0 0 0 0; sleep 0.2
C1=$(px)
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.3
inj_stick -1 0 0 0; sleep 1.5; inj_stick 0 0 0 0; sleep 0.2
E0=$(px)
inj_stick 1 0 0 0; sleep 0.35; inj_stick 0 0 0 0; sleep 0.2
E1=$(px)
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
print("edge test strengthened")
