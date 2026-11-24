VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
prefs(){ cat $(ls /data/misc/*/prefs/com.dennis.dexpad/dexpad.xml 2>/dev/null | head -1) 2>/dev/null; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.3; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
hold_rb(){ $VG key 311 $1 400 >/dev/null 2>&1; }
echo "== getevent -lp device lines =="
getevent -lp 2>/dev/null | grep -a -A2 'add device' | grep -a -B1 -A1 'Gamepad' | head -12
echo "== press test =="
starts; l3
logcat -c
hold_rb 500; sleep 1.0
echo "drag end: $(logcat -d -s DexPad 2>/dev/null | grep -a 'drag end' | tail -1)"
echo "helper DRAG: $(grep -a 'DRAG up' /data/adb/gpm/helper.log | tail -1)"