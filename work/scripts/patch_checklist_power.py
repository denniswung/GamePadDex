import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

anchor = "svc power stayon false >/dev/null 2>&1"
block = '''# ---------- P. power key (Y + L3) ----------
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
L=$(lcount)
/data/local/tmp/vgpad key 308 1200 3000 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 1.5
OFF=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
/data/local/tmp/vgpad key 308 1200 3000 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 2
ON=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
POW=$(ltail "$L" | grep -c 'POWER')
if [ "$POW" -ge 2 ] && [ "$OFF" != "Awake" ] && [ "$ON" = "Awake" ]; then
    ok "P1 power key Y+L3 (off=$OFF on=$ON, POWER=$POW)"
else
    bad "P1 power key Y+L3 (off=$OFF on=$ON, POWER=$POW)"
fi

'''
assert anchor in s
s = s.replace(anchor, block + anchor, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
