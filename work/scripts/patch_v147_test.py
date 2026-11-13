import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_checklist.sh"
s = io.open(p, encoding="utf-8").read()

# right-stick Y is axis 4 (RX=3, RY=4)
s = s.replace("$VG stick 5 20000", "$VG stick 4 20000")
s = s.replace("-20000", "20000") if False else s

# S-03: gesture mode produces SWIPE, wheel mode produces wheel steps
old = s[s.index("# ---- S-03 wheel injection path ----"):s.index("# ---- S-04")]
new = '''# ---- S-03 scroll output paths: gesture vs wheel ----
dbg --es pref v_touch_scroll --ez bval true
sleep 0.4
L=$(hcount)
$VG stick 4 20000 400 2500 >/dev/null 2>&1
sleep 0.8
G=$(hl "$L" | grep -c 'SWIPE')
dbg --es pref v_touch_scroll --ez bval false
sleep 0.4
L=$(hcount)
$VG stick 4 20000 400 2500 >/dev/null 2>&1
sleep 0.8
W=$(hl "$L" | grep -c 'SWIPE')
if [ "$G" -ge 1 ] && [ "$W" -eq 0 ]; then
    ok "S-03 gesture vs wheel backend (swipe=$G wheel=$W)"
else
    bad "S-03 backends (gesture swipe=$G, wheel-mode swipe=$W)"
fi
dbg --es pref v_touch_scroll --ez bval true
sleep 0.4

'''
s = s.replace(old, new)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
