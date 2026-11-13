#!/system/bin/sh
BIN=/data/local/tmp/gpminput
LOG=/data/local/tmp/gpminput.log
pos() {
  dumpsys SurfaceFlinger 2>/dev/null | grep -A6 'LayerFE (\[BBQ\] Sprite' | grep -E '^    [0-9-]' | head -2 | tr -d ' ' | tr '\n' ','
  dumpsys SurfaceFlinger 2>/dev/null | grep -B1 'composition type=CURSOR' | grep -oE 'alpha=[0-9.]+' | head -1
}
echo "== cursor before ==" ; pos
( sleep 1.2; echo "M 60 40"; sleep 0.15; echo "M 60 40"; sleep 0.15; echo "M 60 40"; sleep 0.4; echo "Q" ) | $BIN > $LOG 2>&1
echo "== helper output ==" ; cat $LOG
echo "== cursor after ==" ; pos
