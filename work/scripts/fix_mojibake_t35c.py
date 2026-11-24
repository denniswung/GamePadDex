#!/usr/bin/env python3
"""t35: replace each mojibake-containing line individually (never touches non-garbled
lines), preserving line count. Code before '/*' is kept byte-identical."""
import re
import sys

PATH = 'project/app/src/main/assets/gpminput.c'

# 从 fix_mojibake_t35b.py 里取出 REPL 字典（只 exec 这一段）
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
        t = t.strip()
        if not t:
            continue
        for part in re.split(r'[；。]', t):
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


def format_line(line, chunk):
    if not chunk:
        chunk = '原始说明见代码与文档'
    if '/*' in chunk and not chunk.lstrip().startswith('/*'):
        return chunk          # 整行替换（代码 + 行尾注释）
    idx = line.find('/*')
    if idx > 0 and line[:idx].strip():
        return line[:idx].rstrip() + ' /* ' + chunk + ' */'
    indent = re.match(r'^\s*', line).group(0)
    return indent + '/* ' + chunk + ' */'


replaced = 0
for i, line in enumerate(lines):
    if any(c in clues for c in line):
        lines[i] = format_line(line, chunk_for(i + 1))
        replaced += 1

if '--write' in sys.argv:
    open(PATH, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
    print('wrote: replaced=%d' % replaced)
else:
    print('dry-run: replaced=%d' % replaced)
