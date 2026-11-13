#!/system/bin/sh
pos() {
  dumpsys SurfaceFlinger 2>/dev/null | grep -A6 'LayerFE (\[BBQ\] Sprite' | grep -E '^    [0-9-]' | head -2 | tr -d ' ' | tr '\n' ',' 
  dumpsys SurfaceFlinger 2>/dev/null | grep -B1 'composition type=CURSOR' | grep -oE 'alpha=[0-9.]+' | head -1
}
echo "== before =="; pos
echo "== inject left stick X + =="
/data/local/tmp/vgpad stick 0 32000 1500 2>/dev/null
echo "== after stick =="; pos
echo "== inject HAT right (dpad) =="
/data/local/tmp/vgpad hat 1 0 800 2>/dev/null
echo "== after hat =="; pos
echo "== focus now =="
dumpsys window 2>/dev/null | grep -E 'mCurrentFocus' | head -3
