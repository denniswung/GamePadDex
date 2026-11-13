import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
old = '''# ---------- P. power key (Y + L3) ----------
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
L=$(lcount)'''
new = '''# ---------- P. power key (Y + L3) ----------
# "stay on while charging" would auto-wake the screen and hide the toggle
svc power stayon false >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
L=$(lcount)'''
assert old in s
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
