#!/usr/bin/env python3
"""Recover mojibake comments in gpminput.c by borrowing the correct Chinese text
from the v1.65 version in git HEAD, matching on the ASCII-only signature."""
import re
import subprocess
import sys

path = 'project/app/src/main/assets/gpminput.c'
head = subprocess.run(['git', 'show', 'HEAD:' + path], capture_output=True, check=True).stdout.decode('utf-8')

def ascii_sig(line):
    s = ''.join(ch for ch in line if ord(ch) < 128)
    s = re.sub(r'[ \t]+', ' ', s)
    return s.strip()

head_lines = head.split('\n')
head_map = {}
for i, l in enumerate(head_lines):
    sig = ascii_sig(l)
    if len(sig) >= 6:
        head_map.setdefault(sig, []).append((i, l))

cur = open(path, encoding='utf-8').read().split('\n')
mojibake = re.compile(r'[\u3400-\u9fff]')
recovered = 0
remaining = []
for i, l in enumerate(cur):
    if not mojibake.search(l):
        continue
    sig = ascii_sig(l)
    cands = head_map.get(sig)
    if cands and len(cands) == 1:
        hl = cands[0][1]
        if mojibake.search(hl) and '?' not in hl:
            cur[i] = hl
            recovered += 1
            continue
    remaining.append((i + 1, l))

open(path, 'w', encoding='utf-8').write('\n'.join(cur))
print('recovered=%d remaining=%d' % (recovered, len(remaining)))
for n, l in remaining:
    print('%d\t%s' % (n, l[:120]))
