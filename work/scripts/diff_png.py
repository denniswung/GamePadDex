import sys
from PIL import Image, ImageChops

a = Image.open(r"C:\Users\Dennis\AppData\Local\Temp\c1.png").convert("RGB")
b = Image.open(r"C:\Users\Dennis\AppData\Local\Temp\c2.png").convert("RGB")
print("size", a.size, b.size)
if a.size != b.size:
    sys.exit(0)
diff = ImageChops.difference(a, b)
bbox = diff.getbbox()
print("diff bbox:", bbox)
# 统计差异像素数
import numpy as np
d = np.asarray(diff).sum(axis=2)
n = int((d > 12).sum())
print("changed px:", n, "of", d.size)
ys, xs = np.where(d > 12)
if len(xs):
    print("x range", xs.min(), xs.max(), "y range", ys.min(), ys.max())
