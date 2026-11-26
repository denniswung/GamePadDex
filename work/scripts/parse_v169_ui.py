import re
import sys

for f in sys.argv[1:]:
    t = open(f, encoding='utf-8').read()
    m = re.findall(r'text="([^"]*(?:横向|第 [0-9] 页)[^"]*)"', t)
    print(f, m)
