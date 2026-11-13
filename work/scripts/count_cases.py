import re, io, collections

p = "/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v2.0.md"
s = io.open(p, encoding="utf-8").read()
rows = re.findall(r"^\|\s*([A-Za-z]+\d*-\d+)\s*\|", s, re.M)
print("cases:", len(rows), "unique:", len(set(rows)))
sec = collections.Counter(re.match(r"[A-Za-z]+", r).group(0) for r in rows)
print(sec)
# priority cells anywhere in row
prio = collections.Counter()
for line in s.splitlines():
    m = re.match(r"^\|\s*([A-Za-z]+\d*-\d+)\s*\|.*", line)
    if not m:
        continue
    for pz in ("P0", "P1", "P2"):
        if re.search(r"\|\s*" + pz + r"\s*\|", line):
            prio[pz] += 1
            break
    else:
        prio["none"] += 1
print(prio)
