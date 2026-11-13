import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

start_marker = "# ---------- P. power key (Y + L3) ----------"
end_marker = "# ---------- A. connection ----------"
start = s.find(start_marker)
if start >= 0:
    end = s.find(end_marker, start)
    assert end > start
    block = s[start:end]
    s = s[:start] + s[end:]
else:
    raise SystemExit("power block not found")

anchor = "svc power stayon false >/dev/null 2>&1"
last = s.rfind(anchor)
assert last > 0
s = s[:last] + block + s[last:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("moved P1 to tail")
