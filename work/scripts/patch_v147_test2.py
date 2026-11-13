import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_checklist.sh"
s = io.open(p, encoding="utf-8").read()

# devices is a count, not a capability
s = s.replace("grep ' 0$' | grep -v 'focus_rect'", "grep ' 0$' | grep -vE 'focus_rect|devices'")

# S-07: the rectangle needs ~2 s to arrive, keep the stick down long enough
s = s.replace("$VG stick 4 20000 4000 2500", "$VG stick 4 20000 7000 2500")
s = s.replace("""$VG stick 4 20000 7000 2500 >/dev/null 2>&1
sleep 1
if hl "$L" | grep -q 'FOCUS_ANCHOR'; then""",
"""$VG stick 4 20000 7000 2500 >/dev/null 2>&1
sleep 1.5
if hl "$L" | grep -q 'FOCUS_ANCHOR'; then""")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
