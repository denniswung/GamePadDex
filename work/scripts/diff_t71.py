import sys, os
from PIL import Image, ImageChops

def diff(p1, p2):
    a = Image.open(p1).convert('RGB')
    b = Image.open(p2).convert('RGB')
    if a.size != b.size:
        b = b.resize(a.size)
    d = ImageChops.difference(a, b).convert('L')
    h = d.histogram()
    changed = sum(h[8:])  # ignore tiny noise <8
    total = a.size[0] * a.size[1]
    return 100.0 * changed / total

base = 'work/tmp_t71c'
for pair in [('a', 'b'), ('b', 'c'), ('c', 'd')]:
    p1 = f'{base}_{pair[0]}.png'
    p2 = f'{base}_{pair[1]}.png'
    if os.path.exists(p1) and os.path.exists(p2):
        print(pair, f'{diff(p1, p2):.3f}%')
    else:
        print(pair, 'missing')
