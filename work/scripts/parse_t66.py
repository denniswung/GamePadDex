import re
p = 'work/tmp_t66f.xml'
s = open(p, encoding='utf-8', errors='ignore').read()
for label, pat in [
    ('offset', r'纵向 offset=\d+'),
    ('scrollX', r'横向 scrollX=\d+'),
    ('stat', r'后端统计[^<]{0,40}'),
    ('fixed', r'固定区域[^<]{0,40}'),
    ('firstitem', r'列表项 #\d+'),
]:
    m = re.findall(pat, s)
    print(label, '->', m[:3])
