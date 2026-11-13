from PIL import Image

for name, path in [("h1", r"C:\Users\Dennis\AppData\Local\Temp\h1.png"),
                   ("h2", r"C:\Users\Dennis\AppData\Local\Temp\h2.png")]:
    im = Image.open(path).convert("RGB")
    cx, cy = 1280, 800
    box = (cx - 80, cy - 80, cx + 80, cy + 80)
    im.crop(box).resize((320, 320), Image.NEAREST).save(rf"C:\Users\Dennis\AppData\Local\Temp\{name}_crop.png")
    print(name, im.size, "crop saved")
