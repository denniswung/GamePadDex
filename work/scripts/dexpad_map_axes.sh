#!/system/bin/sh
# map dpad/trigger buttons for the axis-path tests
B=com.dennis.dexpad
set_map() {
    am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button "$1" --es mapped "$2" ${3:+--es value "$3"} >/dev/null 2>&1
}
set_map up home
set_map down recents
set_map left back
set_map right notifications
set_map lt key_combo ctrl+a
set_map rt back
set_map r3 middle_click
set_map guide toggle_mouse
echo mapped
