"""Compute PiliPlus screenshot difference metrics (v1.68 release verification).

Metrics (all on the same 2560x1600 RGB frames, no downscale):
  changed_pct  : fraction (%) of pixels where max channel |delta| > 8
  mae_pct      : mean absolute per-channel difference / 255 * 100
  mean_delta   : mean of (sum of |dR|+|dG|+|dB|)/3 over pixels (0..255)
Also reports a row-shift estimate (vertical scroll distance) by best-match search
of a horizontal band, as a sanity check that the content really scrolled.
"""
import sys
from PIL import Image, ImageChops
import numpy as np


def load(p):
    im = Image.open(p).convert("RGB")
    return np.asarray(im, dtype=np.int16)


def metrics(a, b):
    d = np.abs(a - b)
    changed = (d.max(axis=2) > 8).mean() * 100.0
    mae = d.mean() / 255.0 * 100.0
    rmse = float(np.sqrt((d.astype(np.float64) ** 2).mean())) / 255.0 * 100.0
    mean_delta = d.mean()
    return changed, mae, rmse, mean_delta


def shift_estimate(a, b, max_shift=1200, band=(300, 900)):
    """Estimate vertical content shift between a and b using a horizontal band."""
    ga = a[:, :, 0].astype(np.float32)
    gb = b[:, :, 0].astype(np.float32)
    y0, y1 = band
    band_a = ga[y0:y1, 200:2360]
    best = (None, 1e18)
    for s in range(-max_shift, max_shift + 1, 8):
        y0b, y1b = y0 + s, y1 + s
        if y0b < 0 or y1b > ga.shape[0]:
            continue
        band_b = gb[y0b:y1b, 200:2360]
        diff = np.abs(band_a - band_b).mean()
        if diff < best[1]:
            best = (s, diff)
    return best


def main():
    pairs = [("pili_before", "pili_after"), ("prog0", "prog1"), ("prog1", "prog2"), ("prog2", "prog3"), ("prog0", "prog3")]
    base = sys.argv[1] if len(sys.argv) > 1 else "."
    print("pair                       changed%   mae%   rmse%   mean_delta   best_shift(px)")
    for x, y in pairs:
        a = load("%s/%s.png" % (base, x))
        b = load("%s/%s.png" % (base, y))
        if a.shape != b.shape:
            print("%-24s shape mismatch %s vs %s" % (x + "->" + y, a.shape, b.shape))
            continue
        ch, mae, rmse, md = metrics(a, b)
        s, err = shift_estimate(a, b)
        print("%-24s %8.2f  %6.2f  %6.2f  %9.2f   %+6d (err %.2f)" % (x + "->" + y, ch, mae, rmse, md, s if s is not None else 0, err))


if __name__ == "__main__":
    main()
