import sys

path = sys.argv[1]
raw = open(path, 'rb').read()
text = raw.decode('utf-8')

def looks_chinese(s):
    return any('\u4e00' <= ch <= '\u9fff' for ch in s)

def fix_line(line):
    if all(ord(ch) < 128 for ch in line):
        return line, 0
    for enc in ('gbk', 'gb18030', 'latin-1'):
        try:
            b = line.encode(enc)
        except Exception:
            continue
        try:
            back = b.decode('utf-8')
        except Exception:
            continue
        if back == line:
            continue
        # accept only if the reversal produces plausible text: mostly CJK/ASCII
        bad = sum(1 for ch in back if ch == '\ufffd')
        if bad == 0:
            return back, 1
    return line, 0

out_lines = []
fixed = 0
total_cn = 0
for line in text.split('\n'):
    if looks_chinese(line):
        total_cn += 1
    new, ok = fix_line(line)
    fixed += ok
    out_lines.append(new)

new_text = '\n'.join(out_lines)
open(path, 'wb').write(new_text.encode('utf-8'))
print("lines_with_cjk=%d fixed=%d" % (total_cn, fixed))
