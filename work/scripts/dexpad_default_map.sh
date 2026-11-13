#!/system/bin/sh
# reset the mapping set to the shipped defaults via the debug receiver
B=com.dennis.dexpad
set_map() {
    am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button "$1" --es mapped "$2" >/dev/null 2>&1
}
set_map a left_click
set_map b right_click
set_map x middle_click
set_map y none
set_map lb wheel_up
set_map rb wheel_down
set_map lt none
set_map rt none
set_map up none
set_map down none
set_map left none
set_map right none
set_map l3 none
set_map r3 none
set_map start home
set_map select recents
set_map guide none
set_map share toggle_mouse
echo mapped
