from PIL import Image

p = r"C:\Users\Dennis\AppData\Local\Temp\h1.png"
im = Image.open(p).convert("RGB")
# hover 是显示坐标 (Hx, Hy)，screencap 出来是旋转后的 (Hy, Hx)
for (hx, hy, tag) in [(224, 1520, "hover"), (1280, 800, "center")]:
    cx, cy = hy, hx
    box = (max(0, cx - 60), max(0, cy - 60), min(im.width, cx + 60), min(im.height, cy + 60))
    im.crop(box).resize((300, 300), Image.NEAREST).save(
        rf"C:\Users\Dennis\AppData\Local\Temp\crop_{tag}.png")
    print(tag, box)
