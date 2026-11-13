import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

old = '''/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 1.5
OFF=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
/data/local/tmp/vgpad key 308 1200 3000 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 2'''

new = '''/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 3
OFF=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
/data/local/tmp/vgpad key 308 1200 3000 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad key 317 150 800 >/dev/null 2>&1
sleep 3'''

assert old in s
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
