import numpy as np
from PIL import Image

paths = [r"C:\Users\Dennis\AppData\Local\Temp\h1.png", r"C:\Users\Dennis\AppData\Local\Temp\h2.png"]
a = Image.open(paths[0]).convert("RGB")
b = Image.open(paths[1]).convert("RGB")
print("sizes", a.size, b.size)
if a.size != b.size:
    raise SystemExit
d = np.asarray(a).astype(int) - np.asarray(b).astype(int)
mag = np.abs(d).sum(axis=2)
mask = mag > 24
print("changed px:", int(mask.sum()))
ys, xs = np.where(mask)
if len(xs):
    print("bbox x", xs.min(), xs.max(), "y", ys.min(), ys.max())
