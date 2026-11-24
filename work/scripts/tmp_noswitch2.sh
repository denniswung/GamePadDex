VG=/data/local/tmp/vgpad
PKG=com.dennis.dexpad
set_speed(){ am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref scroll_speed --ei ival "$1" >/dev/null 2>&1; sleep 0.6; }
am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.5
$VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
set_speed 4
logcat -c
$VG key 311 3000 400 >/dev/null 2>&1 &
sleep 1.7
set_speed 10
wait
sleep 1.0
echo "drag start: $(logcat -d -s DexPad | grep -a 'drag start' | tail -1 | sed 's/^.*DexPad *: //')"
echo "drag end:   $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //')"
echo "stop cap:   $(logcat -d -s DexPad | grep -a 'drag stop cap' | tail -1 | sed 's/^.*DexPad *: //')"
set_speed 4