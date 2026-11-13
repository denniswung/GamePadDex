import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

# A2: helper used to report HOME; it is app-agnostic now
old_a2 = '''if grep -q '^HOME ' /data/adb/gpm/helper.log; then ok "A2 home/launcher report"; else bad "A2 home/launcher report"; fi'''
new_a2 = '''if grep -q '^READY' /data/adb/gpm/helper.log && grep -q '^DEV ' /data/adb/gpm/helper.log; then
    ok "A2 helper ready + devices"
else
    bad "A2 helper ready + devices"
fi'''
assert old_a2 in s
s = s.replace(old_a2, new_a2, 1)

# M1: generic up swipe (65% start, ~35% distance), no launcher/app detection
start = s.find("# ---------- M. drawer + notification ----------")
end = s.find("# a fullscreen launcher may swallow the shade gesture", start)
assert start > 0 and end > start
new_m1 = '''# ---------- M. vertical gestures ----------
input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 2
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 700 2000 >/dev/null 2>&1
sleep 2
SW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep 'SWIPE ' | head -1)
SY1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\\([0-9]*\\) ->.*/\\1/p')
SY2=$(echo "$SW" | sed -n 's/.*-> [0-9]*,\\([0-9]*\\).*/\\1/p')
if [ -n "$SY1" ] && [ "$SY1" -ge 800 ] && [ "$SY1" -le 1300 ] && [ "$SY2" -lt "$SY1" ]; then
    ok "M1 generic up swipe ($SW)"
else
    bad "M1 generic up swipe ($SW)"
fi

'''
s = s[:start] + new_m1 + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
