import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

old2 = '''logcat -c
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'A -> DPAD_CENTER (native nav)'; then ok "C2 A activates focus"; else bad "C2 A activates focus"; fi'''
new2 = '''logcat -c
# make sure native arrow navigation is active first
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 0.5
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'A -> DPAD_CENTER (native nav)'; then ok "C2 A activates focus"; else bad "C2 A activates focus"; fi'''
assert old2 in s
s = s.replace(old2, new2, 1)

old4 = '''logcat -c
/data/local/tmp/vgpad stick 0 20000 500 3000 >/dev/null 2>&1
sleep 1
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1'''
new4 = '''logcat -c
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 0.5
/data/local/tmp/vgpad stick 0 20000 500 3000 >/dev/null 2>&1
sleep 1
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1'''
assert old4 in s
s = s.replace(old4, new4, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
