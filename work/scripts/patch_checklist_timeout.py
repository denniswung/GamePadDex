import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

old = '''wake
svc power stayon true >/dev/null 2>&1
'''
new = '''wake
svc power stayon true >/dev/null 2>&1
# never let the screen time out mid-run (battery power ignores stayon)
OLD_TIMEOUT=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
'''
assert old in s
s = s.replace(old, new, 1)

old2 = '''svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"'''
new2 = '''svc power stayon false >/dev/null 2>&1
[ -n "$OLD_TIMEOUT" ] && settings put system screen_off_timeout "$OLD_TIMEOUT"
echo "----------------------------------------"'''
assert old2 in s
s = s.replace(old2, new2, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
