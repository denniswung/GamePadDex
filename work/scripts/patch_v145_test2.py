import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()

s = s.replace("""py() { uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; grep -o 'y=[0-9.]*' /sdcard/ui.xml 2>/dev/null | head -1 | cut -d= -f2; }
px() { uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; grep -o 'x=[0-9.]*' /sdcard/ui.xml 2>/dev/null | head -1 | cut -d= -f2; }""",
"""py() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at ([0-9.]*, //;s/)//'; }
px() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at (//;s/,.*//'; }""")

# K-10: one process presses L3 then the stick 150 ms later (inside the ignore window)
old = s[s.index("# ---- L3 centre + ignore stick ----"):s.index("# ---- R3 double + cancel")]
new = """# ---- L3 centre + ignore stick ----
L=$(hcount)
for i in 1 2 3; do
    $VG key 317 100 2500 >/dev/null 2>&1
    sleep 0.3
    hl "$L" | grep -q CENTER && break
done
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
$VG key 317 100 2500 >/dev/null 2>&1
sleep 0.3
P0=$(py)
$VG holdstick 317 1 -20000 400 2500 >/dev/null 2>&1
sleep 0.4
P1=$(py)
[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "K-10 L3 centre + stick lock" || bad "K-10 L3 lock ($P0->$P1)"

"""
s = s.replace(old, new)

# R3 double + cancel
old = s[s.index("# ---- R3 double + cancel on right stick ----"):s.index("# ---- GUIDE help")]
new = """# ---- R3 double + cancel on right stick ----
logcat -c
for i in 1 2 3; do
    L=$(hcount)
    $VG double 318 60 110 2500 >/dev/null 2>&1
    sleep 0.6
    hl "$L" | grep -q 'KEYON 0 85' && break
done
hl "$L" | grep -q 'KEYON 0 85' && ok "K-12 R3 double play/pause" || bad "K-12 R3 double"
logcat -c
for i in 1 2 3; do
    $VG dblstick 318 120 4 20000 2500 >/dev/null 2>&1
    sleep 0.5
    log | grep -q 'double r3 cancelled' && break
done
log | grep -q 'double r3 cancelled' && ok "K-12 R3 double cancelled by stick" || bad "K-12 R3 cancel"

"""
s = s.replace(old, new)

# volume: v1.43 injects KEYCODE_VOLUME_UP (24) via pointKey -> KEYON, not KCOMBO
s = s.replace("""V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
[ "$V" -ge 2 ]""",
"""V=$(hl "$L" | grep -c 'KEYON 0 24')
[ "$V" -ge 2 ]""")

# slow pointer: plain stick vs X-held stick (hover coordinates)
old = s[s.index("# ---- X + left stick slow pointer ----"):s.index("# ---- role swap")]
new = """# ---- X + left stick slow pointer ----
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
$VG key 317 100 2500 >/dev/null 2>&1; sleep 0.4
A0=$(py); $VG stick 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; A1=$(py)
$VG key 317 100 2500 >/dev/null 2>&1; sleep 0.4
B0=$(py); $VG holdstick 307 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; B1=$(py)
DA=$(awk -v a="$A0" -v b="$A1" 'BEGIN{printf "%.0f",(b-a<0?a-b:b-a)}')
DB=$(awk -v a="$B0" -v b="$B1" 'BEGIN{printf "%.0f",(b-a<0?a-b:b-a)}')
[ -n "$DA" ] && [ "$DA" -gt 0 ] && [ "$DB" -lt $((DA * 60 / 100)) ] && ok "X-05 X+left stick slow ($DB < $DA)" || bad "X-05 slow pointer ($DA vs $DB)"

"""
s = s.replace(old, new)

# role swap: hover deltas
old = s[s.index("# ---- role swap (通用 R1) ----"):s.index("# ---- wake on connect")]
new = """# ---- role swap (通用 R1) ----
setbool role_swap true; sleep 0.6
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1; sleep 1
P0=$(py); $VG stick 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; P1=$(py)
Q0=$(py); $VG stick 3 20000 400 2500 >/dev/null 2>&1; sleep 0.4; Q1=$(py)
[ "$P0" = "$P1" ] && ! [ "$Q0" = "$Q1" ] && ok "R1 role swap (left=scroll right=pointer)" || bad "R1 role swap ($P0->$P1 / $Q0->$Q1)"
setbool role_swap false; sleep 0.3

"""
s = s.replace(old, new)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
