from PIL import Image
im = Image.open(r"E:\Dennis\GamePadDex复刻\work\shots\imm.png").convert("RGB")
w, h = im.size
print("size", w, h)
# Bilibili window caption strip: find the window top-right area.
# Scan rows 0..120 for bright pixels in the right half (caption icons are light on dark).
px = im.load()
for y in range(0, 130, 6):
    runs = []
    for x in range(int(w*0.55), w):
        r,g,b = px[x,y]
        if r>190 and g>190 and b>190:
            runs.append(x)
    if runs:
        # group into clusters
        groups=[]
        cur=[runs[0]]
        for v in runs[1:]:
            if v-cur[-1] <= 6: cur.append(v)
            else: groups.append(cur); cur=[v]
        groups.append(cur)
        groups=[g for g in groups if len(g)>=3]
        if groups:
            print(y, [(g[0]+g[-1])//2 for g in groups][:12])