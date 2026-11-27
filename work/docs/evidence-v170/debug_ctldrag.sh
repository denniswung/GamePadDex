#!/system/bin/sh
# debug ctl drag on release v1.70
CTL=/data/local/tmp/gpmctl
SOCK=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
ctl(){ $CTL "$SOCK" "$@" 2>&1; }
exp(){ am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
  sleep 1.2; logcat -d | grep -a 'EXPORT what=report' | tail -1 | sed 's/.*path=//;s/ size=.*//'; }
field(){ grep -o "\"$2\": *[0-9-]*" "$1" 2>/dev/null | head -1 | sed 's/.*: *//'; }

am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.8
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
echo "top=$(dumpsys activity activities | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
ctl j; sleep 0.5
ctl P 1280 1000 2560 1600; sleep 0.6
f=$(exp); echo "voff_before=$(field "$f" vertical_offset) hx=$(field "$f" horizontal_scroll_x) f=$f"
logcat -c
echo "--- d ---"; ctl d 0 1280 1000
echo "--- m1 ---"; ctl m 0 -500 0 400
sleep 0.4
echo "--- m2 ---"; ctl m 0 0 800 400
sleep 0.4
echo "--- e ---"; ctl e 0
sleep 1.0
f2=$(exp); echo "voff_after=$(field "$f2" vertical_offset) hx=$(field "$f2" horizontal_scroll_x)"
echo "--- logcat DexPad ---"; logcat -d -s DexPad | tail -6
echo "--- logcat PadProbe ---"; logcat -d -s PadProbe | tail -8
echo "--- helper tail ---"; tail -12 /data/adb/gpm/helper.log
