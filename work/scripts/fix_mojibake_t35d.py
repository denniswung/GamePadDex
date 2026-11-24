#!/usr/bin/env python3
"""t35: replace whole comment blocks that contain mojibake with one correct Chinese
comment line.  Never touches code lines; block boundaries are detected and validated."""
import re
import sys

PATH = 'project/app/src/main/assets/gpminput.c'
src_lines = open('work/scripts/fix_mojibake_t35b.py', encoding='utf-8').read().split('\n')
start = next(i for i, l in enumerate(src_lines) if l.startswith('REPL = {'))
end = start
while end < len(src_lines) and src_lines[end].strip() != '}':
    end += 1
ns = {}
exec(compile('\n'.join(src_lines[start:end + 1]), 'repl', 'exec'), ns)
REPL = ns['REPL']

lines = open(PATH, encoding='utf-8').read().split('\n')
clues = set('锛銆鈥鎸鍚鐨缁瀹浠鏄鍦韬绯缂绋寮鍙涓闃鍧閿骞鎴浣鏂鏃鏋鏍鐢鍒鍔鍛鍜鍝鍞鍟鍢鍤鍥鍨鍩鍫鍬鍮鍰鍲鍴鍶鍸鍺鍼鍾鐀鐂鐄鐆鐈鐊鐌鐎鐓鐕鐗鐙鐝鐟鐡鐣鐥鐧鐩鐫鐭鐯鐱鐳鐵鐷鐹鐻鐽鐿鑺锟斤拷')


def chunks_of(texts):
    out = []
    for t in texts:
        for part in re.split(r'[；。]', t.strip()):
            part = part.strip()
            if part:
                out.append(part)
    return out or ['']


regions = sorted((s, e, chunks_of(t)) for s, (e, t) in REPL.items())


def chunk_for(n):
    for s, e, ch in regions:
        if s <= n <= e:
            off = n - s
            return ch[off] if off < len(ch) else ch[-1]
    return ''


def is_garbled(line):
    return any(c in clues for c in line)


comment_re = re.compile(r'^\s*(/\*|\*|\*/)')
out = []
i = 0
replaced_lines = 0
while i < len(lines):
    line = lines[i]
    code_comment = line.find('/*') > 0 and line[:line.find('/*')].strip() and '*/' in line
    if code_comment and is_garbled(line):
        chunk = chunk_for(i + 1) or '见代码与文档'
        if '/*' in chunk:
            chunk = chunk[chunk.find('/*') + 2:]
            chunk = chunk.rstrip()
            if chunk.endswith('*/'):
                chunk = chunk[:-2]
            chunk = chunk.strip()
        out.append(line[:line.find('/*')] + '/* ' + chunk + ' */')
        replaced_lines += 1
        i += 1
        continue
    if line.find('/*') >= 0 and not code_comment and ('*/' not in line or is_garbled(line)):
        # 找块首：向上直到含 /* 的行（只允许注释行）
        op = i
        while op > 0 and '/*' not in lines[op]:
            op -= 1
        cl = i
        while cl < len(lines) - 1 and '*/' not in lines[cl]:
            cl += 1
        block = lines[op:cl + 1]
        if all(comment_re.match(x) for x in block):
            g = [k for k in range(op, cl + 1) if is_garbled(lines[k])]
            chunk = chunk_for(g[0] + 1) if g else '说明见代码与文档'
            out.append('/* ' + chunk + ' */')
            replaced_lines += len(block)
            i = cl + 1
            continue
    out.append(line)
    i += 1

print('blocks/lines replaced=%d, output lines=%d (input %d)' % (replaced_lines, len(out), len(lines)))
if '--write' in sys.argv:
    open(PATH, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('wrote', PATH)
