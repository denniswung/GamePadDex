import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v146_checklist.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index("# ---- 3. X/Y sensitivity ----")
end = s.index("# ---- 4. export / profile ----")
new = '''# ---- 3. X/Y sensitivity ----
setpref mix_0_action none; setpref mix_1_action none
pos() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at (//;s/)//'; }
travel() { # $1 = sens_x percent, echoes the pointer travel in px
    setprefi sens_x "$1"; sleep 0.6
    am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
    sleep 1.4
    $VG key 317 100 2500 >/dev/null 2>&1
    sleep 3.4
    P0=$(pos)
    $VG stick 0 20000 300 2500 >/dev/null 2>&1
    sleep 0.6
    P1=$(pos)
    awk -v a="$P0" -v b="$P1" 'BEGIN{
        split(a, x, ","); split(b, y, ",");
        dx = y[1] - x[1]; dy = y[2] - x[2];
        if (dx < 0) dx = -dx; if (dy < 0) dy = -dy;
        printf "%.0f", (dx > dy ? dx : dy)
    }'
}
DA=0; DB=0
for attempt in 1 2 3; do
    DA=$(travel 100)
    DB=$(travel 50)
    [ -n "$DA" ] && [ "$DA" -gt 0 ] && break
    sleep 0.5
done
if [ -n "$DA" ] && [ "$DA" -gt 0 ] && [ "$DB" -lt $((DA * 70 / 100)) ]; then
    ok "S-11 X sensitivity 50% ($DB < $DA)"
else
    bad "S-11 sens ($DA vs $DB)"
fi
setprefi sens_x 100
sleep 0.4

'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
