import re, sys, collections
x = open(sys.argv[1], encoding='utf-8', errors='ignore').read()
texts = [m.group(1) for m in re.finditer(r'text="([^"]+)"', x)]
ids = [m.group(1) for m in re.finditer(r'resource-id="([^"]+)"', x)]
print('nodes', x.count('<node'))
print('texts:', collections.Counter(texts).most_common(20))
print('ids:', collections.Counter(ids).most_common(20))
