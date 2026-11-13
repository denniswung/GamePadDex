import xml.etree.ElementTree as ET
import sys

path = r'E:\Dennis\GamePadDex复刻\work\probe\win.xml'
tree = ET.parse(path)
root = tree.getroot()

def walk(node, depth):
    a = node.attrib
    cls = a.get('class', '')
    rid = a.get('resource-id', '')
    text = a.get('text', '')
    desc = a.get('content-desc', '')
    bounds = a.get('bounds', '')
    extra = ''
    if text:
        extra += ' text="%s"' % text
    if desc:
        extra += ' desc="%s"' % desc
    print('%s%s%s id=%s%s bounds=%s' % ('  ' * depth, cls.split('.')[-1], '', rid, extra, bounds))
    for child in node:
        walk(child, depth + 1)

walk(root, 0)
