from PIL import Image

im = Image.open(r"C:\Users\Dennis\AppData\Local\Temp\s1.png").convert("RGB")
print("size", im.size)
# hover (224, 1739) 是显示坐标(1600x2560)；截图是 2560x1600，所以交换
cx, cy = 1739, 224
box = (max(0, cx - 90), max(0, cy - 90), min(im.width, cx + 90), min(im.height, cy + 90))
im.crop(box).resize((360, 360), Image.NEAREST).save(r"C:\Users\Dennis\AppData\Local\Temp\s1_crop.png")
print("crop box", box)
