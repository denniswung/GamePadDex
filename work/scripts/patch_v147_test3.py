import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_checklist.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index("# ---- S-04 控件级焦点")
end = s.index("# ---- S-07 wheel anchor")
new = '''# ---- S-04 控件级焦点: scroll with focus enabled, expect a focus rect ----
setbool focus_scroll true
sleep 0.5
got=0
for attempt in 1 2 3 4 5; do
    am start -n com.android.settings/.Settings >/dev/null 2>&1
    sleep 2
    # make sure the current screen really has a scrollable control
    uiautomator dump --compressed /data/local/tmp/v147_ui.xml >/dev/null 2>&1
    SC=$(grep -o 'scrollable="true"' /data/local/tmp/v147_ui.xml 2>/dev/null | wc -l)
    L=$(hcount)
    $VG stick 4 20000 3000 2500 >/dev/null 2>&1
    sleep 2.5
    if hl "$L" | grep -q 'FOCUS_SET'; then got=1; break; fi
done
if [ "$got" = 1 ]; then
    RECT=$(hl "$L" | grep -m1 'FOCUS_SET' | sed 's/FOCUS_SET //')
    ok "S-04 控件级焦点 captured ($RECT, scrollable nodes=$SC)"
else
    bad "S-04 focus capture (scrollable=$SC, none=$(hl "$L" | grep -c FOCUS_NONE))"
fi

# the next swipe must report the focus rect as its bounds
L=$(hcount)
$VG stick 4 20000 3000 2500 >/dev/null 2>&1
sleep 2.5
SW=$(hl "$L" | grep -m1 'SWIPE ')
echo "      $SW"
if echo "$SW" | grep -q '(focus '; then
    ok "S-05 swipe uses focus bounds"
else
    bad "S-05 swipe bounds ($SW)"
fi

# ---- S-06 focus disabled falls back to task bounds ----
setbool focus_scroll false
sleep 0.8
L=$(hcount)
$VG stick 4 20000 3000 2500 >/dev/null 2>&1
sleep 2.5
SW2=$(hl "$L" | grep -m1 'SWIPE ')
if echo "$SW2" | grep -q '(task '; then
    ok "S-06 focus off -> task bounds"
else
    bad "S-06 fallback ($SW2)"
fi
setbool focus_scroll true
sleep 0.5

'''
s = s[:start] + new + s[end:]

# S-07: give the rectangle time to come back after being re-enabled
s = s.replace("""setpref_vtouch false
sleep 0.5
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
L=$(hcount)""",
"""setpref_vtouch false
sleep 0.5
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
L=$(hcount)
$VG stick 4 20000 1500 2500 >/dev/null 2>&1
sleep 2.5
L=$(hcount)""")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
