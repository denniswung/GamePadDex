#!/system/bin/sh
# freeze the user's tuned setup as the current mapping set (matches the new code defaults)
B=com.dennis.dexpad
set_map() {
    if [ -n "$3" ]; then
        am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button "$1" --es mapped "$2" --es value "$3" >/dev/null 2>&1
    else
        am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es button "$1" --es mapped "$2" >/dev/null 2>&1
    fi
}
set_map a left_click
set_map b back
set_map x recents
set_map y home
set_map lb wheel_up
set_map rb wheel_down
set_map lt zoom_out
set_map rt zoom_in
set_map up arrow_up
set_map down arrow_down
set_map left arrow_left
set_map right arrow_right
set_map l3 center_cursor
set_map r3 none
set_map start switch_app
set_map select maximize_window
set_map guide key_combo alt+f4
set_map share toggle_mouse
echo mapped
