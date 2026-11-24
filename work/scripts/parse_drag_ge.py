#!/usr/bin/env python3
# parse_drag_ge.py -- 统计 getevent -lt 抓包里的 ABS_MT_POSITION_Y 分步
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'work/tmp_drag_ge.txt'
pat = re.compile(r'\[\s*([0-9]+\.[0-9]+)\]\s+EV_ABS\s+ABS_MT_POSITION_Y\s+([0-9a-fA-F]+)')
rows = []
for line in open(path, encoding='utf-8', errors='replace'):
    m = pat.search(line)
    if m:
        rows.append((float(m.group(1)), int(m.group(2), 16)))

if not rows:
    print('no ABS_MT_POSITION_Y events')
    sys.exit(1)

gaps = [(rows[i][0] - rows[i - 1][0]) * 1000 for i in range(1, len(rows))]
mono_inc = all(rows[i][1] >= rows[i - 1][1] for i in range(1, len(rows)))
mono_dec = all(rows[i][1] <= rows[i - 1][1] for i in range(1, len(rows)))
print('events=%d' % len(rows))
print('first=%d last=%d delta=%d' % (rows[0][1], rows[-1][1], rows[-1][1] - rows[0][1]))
print('gap_ms min=%.2f max=%.2f mean=%.2f' % (min(gaps), max(gaps), sum(gaps) / len(gaps)))
print('monotonic_inc=%s monotonic_dec=%s' % (mono_inc, mono_dec))
viol = [g for g in gaps if g < 8 or g > 20]
print('gaps_out_of_8_20=%d%s' % (len(viol), (' ' + str(viol[:5])) if viol else ''))
