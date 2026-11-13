import io

p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v21_final.sh"
s = io.open(p, encoding="utf-8").read()

# --- L3: wait for CENTER, then push the stick immediately (pre=0) ---
start = s.index("# 4 L3 centre lock")
end = s.index("# 5 GUIDE help")
s = s[:start] + '''# 4 L3 centre lock: wait for CENTER, then push the stick right away
v2 --el center_lock_ms 4000; sleep 0.5
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
for i in 1 2 3; do
    L=$(hcount)
    $VG key 317 100 0 >/dev/null 2>&1
    sleep 0.3
    hl "$L" | grep -q CENTER && break
done
P0=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
$VG stick 0 20000 300 0 >/dev/null 2>&1
sleep 0.4
P1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "L3 centre lock" || bad "L3 centre lock ($P0 -> $P1)"
v2 --el center_lock_ms 250; sleep 0.3

''' + s[end:]

# --- force stop: one process, X then GUIDE ---
start = s.index("# 6 X + GUIDE long = force stop")
end = s.index("# 7 SELECT+START")
s = s[:start] + '''# 6 X + GUIDE long = force stop
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG combo 307 316 2200 0 >/dev/null 2>&1
    sleep 0.6
    log | grep -q 'force stop by X+GUIDE' && break
done
if log | grep -q 'force stop by X+GUIDE' && hl "$L" | grep -q 'CLOSE_APP'; then
    ok "X+GUIDE force stop"
else
    bad "X+GUIDE force stop (force=$(log | grep -c 'force stop') close=$(hl "$L" | grep -c CLOSE_APP))"
fi

''' + s[end:]

# --- mutual exclusion: one process presses LB then moves the stick ---
start = s.index("# 9 LB scroll starts")
end = s.index("# 10 X+up volume")
s = s[:start] + '''# 9 LB scroll starts, right stick stops it (one virtual pad, one process)
logcat -c
for i in 1 2 3; do
    $VG holdstick 310 3 20000 2500 0 >/dev/null 2>&1
    sleep 0.4
    log | grep -q 'hold start lb' && break
done
if log | grep -q 'hold start lb' && log | grep -q 'hold stop lb'; then
    ok "right stick stops LB scroll"
else
    bad "mutual exclusion (start=$(log | grep -c 'hold start lb') stop=$(log | grep -c 'hold stop lb'))"
fi

''' + s[end:]

# --- volume: combo in one process, wait, then inspect the helper log ---
start = s.index("# 10 X+up volume")
end = s.index("# 11 edge slowdown")
s = s[:start] + '''# 10 X+up volume (combo + 300 ms hold delay)
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG combo 307 544 1100 0 >/dev/null 2>&1
    sleep 0.6
    log | grep -q 'combo x+up' && break
done
V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
[ "$V" -ge 1 ] && ok "X+up volume (combo 24)" || bad "X+up volume"

''' + s[end:]

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("v21_final updated")
