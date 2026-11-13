from PIL import Image
im = Image.open(r"E:\Dennis\GamePadDex复刻\work\shots\fsB.png").convert("RGB")
w,h = im.size
px = im.load()
# caption strip is the top ~52px; icons are light pixels on dark bg
for y in range(8, 48, 4):
    xs=[]
    for x in range(int(w*0.75), w):
        r,g,b = px[x,y]
        if r>150 and g>150 and b>150: xs.append(x)
    if not xs: continue
    groups=[]; cur=[xs[0]]
    for v in xs[1:]:
        if v-cur[-1]<=8: cur.append(v)
        else: groups.append(cur); cur=[v]
    groups.append(cur)
    groups=[g for g in groups if len(g)>=4]
    if groups:
        print(y, [ (g[0]+g[-1])//2 for g in groups ])