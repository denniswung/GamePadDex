import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()
start = src.index("static void cmd_center(")
end = src.index("\n}\n", start) + 3

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    /* clamp to the display corner, then jump half a screen in display units.
     * move_display() rotates the delta into raw relative units, and the raw
     * value must be divided by the measured gain. */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(90 * 1000);
    move_display((maxX / 2) / g_pointer_gain, (maxY / 2) / g_pointer_gain, rot);
    usleep(160 * 1000);
    out("CENTER(corner+gain) -> target %d,%d (gain %.2f)", maxX / 2, maxY / 2, g_pointer_gain);
}
'''
src = src[:start] + new + src[end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
