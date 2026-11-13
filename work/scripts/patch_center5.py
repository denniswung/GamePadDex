import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()
start = src.index("static void cmd_center(")
end = src.index("\n}\n", start) + 3

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park;
    if (maxX <= 0) maxX = 904;
    if (maxY <= 0) maxY = 2316;
    int tx = maxX / 2, ty = maxY / 2;
    /* hover coordinates equal display coordinates while the pointer is over a
     * full-screen window, which is the normal case; iterate with the measured
     * raw->pixel gain until the residual is tiny */
    int x = -1, y = -1;
    read_pointer(&x, &y);
    int sx = x, sy = y;
    int tries = 0;
    while (tries < 6) {
        if (x < 0 || y < 0) {
            /* no sample yet: nudge to produce one */
            cmd_mouse_move(30.0, 30.0);
            usleep(80 * 1000);
            read_pointer(&x, &y);
            tries++;
            continue;
        }
        if (abs(tx - x) <= 6 && abs(ty - y) <= 6) break;
        move_display((tx - x) / g_pointer_gain, (ty - y) / g_pointer_gain, rot);
        usleep(110 * 1000);
        read_pointer(&x, &y);
        tries++;
    }
    out("CENTER(iter) -> %d,%d (target %d,%d, start %d,%d)", x, y, tx, ty, sx, sy);
}
'''
src = src[:start] + new + src[end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
