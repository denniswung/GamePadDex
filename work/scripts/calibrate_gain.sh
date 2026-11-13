#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
echo "wm size: $(wm size | tr '\n' ' ')"

for g in 1.00 1.30 1.60 1.90 2.16 2.50 3.00; do
    am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "g $g" >/dev/null 2>&1
    sleep 1.0
    ACK=$(grep -a 'GAIN' /data/adb/gpm/helper.log | tail -1)
    $VG stick 0 20000 500 2000 >/dev/null 2>&1
    sleep 0.2
    $VG stick 4 20000 500 0 >/dev/null 2>&1
    sleep 0.3
    $VG key 317 100 1200 >/dev/null 2>&1
    sleep 3.3
    logcat -c
    $VG stick 0 1500 120 0 >/dev/null 2>&1
    sleep 0.4
    echo "设置=$g [$ACK] 落点=$(hover)"
done
