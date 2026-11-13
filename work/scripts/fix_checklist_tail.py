import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
i = s.rfind('bad "P1 power key')
assert i > 0
end = s.find("\nfi\n", i)
assert end > 0
end += len("\nfi\n")
tail = ('\nsvc power stayon false >/dev/null 2>&1\n'
        'echo "----------------------------------------"\n'
        'echo "PASS=$PASS FAIL=$FAIL"\n'
        '[ "$FAIL" -eq 0 ] || exit 1\n')
s = s[:end] + tail
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("tail fixed")
