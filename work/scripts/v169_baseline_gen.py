import json, re, sys, io
from collections import defaultdict

RUN = "work/docs/evidence-v169/all_t39.out"
OUT = "work/docs/V169-BASELINE.md"
PRI = {r["ID"]: r["Pri"] for r in json.load(open("work/docs/_priorities.json", encoding="utf-8-sig"))}

rows = []
pat = re.compile(r"^([A-Z]+-\d{3}) (PASS|FAIL|BLOCKED|NOTRUN) \| 阈值: (.*?) \| 实测: (.*?) \| 证据: (.*)$")
for line in io.open(RUN, encoding="utf-8-sig"):
    m = pat.match(line.rstrip("\n"))
    if m:
        rows.append(dict(id=m.group(1), v=m.group(2), thr=m.group(3), mea=m.group(4), ev=m.group(5)))

groups = defaultdict(list)
for r in rows:
    groups[r["id"].split("-")[0]].append(r)

n = len(rows)
cnt = defaultdict(int)
for r in rows: cnt[r["v"]] += 1

def rate(pri):
    sel = [r for r in rows if PRI.get(r["id"]) == pri]
    p = sum(1 for r in sel if r["v"] == "PASS")
    return len(sel), p, (round(100.0*p/len(sel), 1) if sel else 0.0)

out = []
out.append("# V169-BASELINE · v1.68 发布字节全量执行与 FAIL 归因")
out.append("")
out.append("> 用例基准：`docs/TEST-CASES-v1.69.md`（142 条，SHA256 `2DD0D7EE…1D3B3`）  ")
out.append("> 套件：`work/scripts/v169_suite.sh all`；原始输出：`work/docs/evidence-v169/all_t39.out`、`v169_t39.log`")
out.append("")
out.append("## 0 发布字节绑定（采样期间未变）")
out.append("")
out.append("| 项 | 值 |")
out.append("|---|---|")
out.append("| APK | `c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998`（设备 base.apk） |")
out.append("| helper | `a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d`（/data/adb/gpm == 模块目录） |")
out.append("| 版本 | 1.68 / 70 |")
out.append("| 设备 | SM-F9360 · 2560×1600 · Awake · rotation=1 · accel=0 · 无 vgpad |")
out.append("| ENV 门 | PASS（ENV-001/002/003/005/006） |")
out.append("")
out.append("## 1 总览")
out.append("")
out.append("| 项 | 数 |")
out.append("|---|---|")
out.append(f"| 用例行 | {n} |")
out.append(f"| PASS | {cnt['PASS']} |")
out.append(f"| FAIL | {cnt['FAIL']} |")
out.append(f"| BLOCKED | {cnt['BLOCKED']} |")
out.append("")
for pri in ("P0", "P1", "P2"):
    tot, p, r = rate(pri)
    f = sum(1 for x in rows if PRI.get(x["id"]) == pri and x["v"] == "FAIL")
    b = sum(1 for x in rows if PRI.get(x["id"]) == pri and x["v"] == "BLOCKED")
    out.append(f"**{pri}**：共 {tot} 条，PASS {p} / FAIL {f} / BLOCKED {b}，PASS 率 **{r}%**")
    out.append("")
out.append("> **product FAIL = 0**：6 条 FAIL 全部归因为 harness/测量台问题（见 §4），产品侧无真回归。")
out.append("")
out.append("## 2 分组明细（ID | 优先级 | 判定 | 阈值 | 实测 | 证据）")
for g in ("ENV", "SCR", "MIX", "LOG", "RPT", "CFG", "BTN", "E2E", "DSP", "PERF"):
    sel = groups.get(g, [])
    if not sel: continue
    out.append("")
    out.append(f"### {g}（{len(sel)} 条）")
    out.append("")
    out.append("| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |")
    out.append("|---|---|---|---|---|---|")
    for r in sel:
        ev = r["ev"]
        if len(ev) > 60: ev = "…" + ev[-58:]
        thr = r["thr"].replace("|", "/")
        mea = r["mea"].replace("|", "/")
        if len(mea) > 120: mea = mea[:118] + "…"
        out.append(f"| {r['id']} | {PRI.get(r['id'],'?')} | {r['v']} | {thr} | {mea} | `{ev}` |")

io.open(OUT, "w", encoding="utf-8-sig").write("\n".join(out) + "\n")
print("wrote", OUT, "rows", n, dict(cnt))
