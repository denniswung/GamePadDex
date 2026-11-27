from PIL import Image, ImageChops

def diff(p1, p2):
    a = Image.open(p1).convert('RGB')
    b = Image.open(p2).convert('RGB')
    if a.size != b.size:
        b = b.resize(a.size)
    h = ImageChops.difference(a, b).convert('L').histogram()
    return 100.0 * sum(h[8:]) / (a.size[0] * a.size[1])

base = 'work/tmp_t71y'
print('size:', Image.open(base + '_a.png').size)
for x, y in [('a', 'b'), ('b', 'c')]:
    print(x, '->', y, '%.3f%%' % diff(f'{base}_{x}.png', f'{base}_{y}.png'))
