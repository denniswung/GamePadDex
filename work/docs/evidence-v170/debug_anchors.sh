#!/system/bin/sh
# scan anchors: which y lets a ctl vertical drag change instrumentation.vertical_offset?
CTL=/data/local/tmp/gpmctl
SOCK=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
exp(){ am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
  sleep 1.1; logcat -d | grep -a 'EXPORT what=report' | tail -1 | sed 's/.*path=//;s/ size=.*//'; }
field(){ grep -o "\"$2\": *[0-9-]*" "$1" 2>/dev/null | head -1 | sed 's/.*: *//'; }
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.8; cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
ctl j >/dev/null 2>&1; sleep 0.5
for y in 700 900 1100 1300 1450; do
  ctl P 1280 $y 2560 1600 >/dev/null 2>&1; sleep 0.5
  f0=$(exp); v0=$(field "$f0" vertical_offset); h0=$(field "$f0" horizontal_scroll_x)
  ctl d 0 1280 $y >/dev/null 2>&1
  ctl m 0 0 -400 400 >/dev/null 2>&1
  sleep 0.5
  ctl e 0 >/dev/null 2>&1
  sleep 0.8
  f1=$(exp); v1=$(field "$f1" vertical_offset); h1=$(field "$f1" horizontal_scroll_x)
  echo "y=$y  voff $v0->$v1  hx $h0->$h1"
done
echo "--- last PadProbe ---"; logcat -d -s PadProbe | grep -a 'TOUCH/swipe\|vertical' | tail -6
