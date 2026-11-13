import re, sys
path = sys.argv[1]
needle = sys.argv[2]
x = open(path, encoding='utf-8', errors='ignore').read()
for m in re.finditer(r'<node[^>]*text="([^"]*)"[^>]*bounds="([^"]+)"', x):
    if needle in m.group(1):
        print(repr(m.group(1)), m.group(2))
