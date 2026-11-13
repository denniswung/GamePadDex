#!/system/bin/sh
# restore the default-ish mapping set (debug receiver) and open the mapping page
B="com.dennis.dexpad"
for p in a:left_click b:right_click x:recents y:key_combo lb:notifications rb:wheel_down l3:toggle_mouse start:home select:back; do
    btn=${p%%:*}
    act=${p##*:}
    am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button "$btn" --es mapped "$act" >/dev/null 2>&1
done
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button y --es mapped key_combo --es value ctrl+a >/dev/null 2>&1
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button x --es mapped key_combo --es value alt+tab >/dev/null 2>&1
input -d 0 keyevent BACK
sleep 1
am start --display 0 -n $B/.ConfigActivity >/dev/null 2>&1
sleep 2
input -d 0 swipe 450 1800 450 600 300
sleep 1
input -d 0 swipe 450 1800 450 600 300
sleep 1
echo done
