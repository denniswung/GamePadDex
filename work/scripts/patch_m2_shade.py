import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

old = '''if [ -n "$SY1" ] && [ "$SY1" -le 400 ] && [ "$SY2" -gt "$SY1" ] && [ "$M3" -gt 1800000 ]; then'''
new = '''SH=$(dumpsys window 2>/dev/null | grep -c NotificationShade)
if [ -n "$SY1" ] && [ "$SY1" -le 400 ] && [ "$SY2" -gt "$SY1" ] && { [ "$M3" -gt 1800000 ] || [ "$SH" -gt 12 ]; }; then'''
assert old in s
s = s.replace(old, new, 1)
s = s.replace('bad "M2 notification shade ($SW, $M3, wake=$WAKE2 top=$TOP2)"',
              'bad "M2 notification shade ($SW, $M3, shade=$SH, wake=$WAKE2 top=$TOP2)"')
s = s.replace('ok "M2 notification shade ($SW, $M3)"',
              'ok "M2 notification shade ($SW, $M3, shade=$SH)"')
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
