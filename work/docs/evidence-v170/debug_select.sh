#!/system/bin/sh
# recheck SELECT -> notification shade on v1.70 release bytes
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
shade(){ dumpsys notification 2>/dev/null | grep -a 'mNotificationShadeWindow' | head -1; }
shade2(){ dumpsys window 2>/dev/null | grep -aE 'NotificationShade|mCurrentFocus' | head -2; }
echo "=== before ==="
cmd statusbar collapse >/dev/null 2>&1; sleep 1.0
shade2
for i in 1 2 3; do
  cmd statusbar collapse >/dev/null 2>&1; sleep 1.0
  B=$(shade2 | tr '\n' '|')
  : > "$HL"
  $VG key 314 120 300 >/dev/null 2>&1
  sleep 1.6
  A=$(shade2 | tr '\n' '|')
  N=$(grep -ac '^NOTIF swipe' "$HL")
  R=$(grep -a '^NOTIF swipe' "$HL" | tail -1)
  echo "try$i NOTIF_lines=$N  rc_line=[$R]"
  echo "  before=[$B]"
  echo "  after =[$A]"
  echo "  shade_expanded=$(dumpsys notification 2>/dev/null | grep -ac 'mNotificationShadeWindow')"
  sleep 0.5
done
cmd statusbar collapse >/dev/null 2>&1
