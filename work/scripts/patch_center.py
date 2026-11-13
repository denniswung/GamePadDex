import re, io, sys

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

start = src.index("static void cmd_center(")
end = src.index("\n}\n", start) + 3
old = src[start:end]

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)maxX; (void)maxY; (void)park; (void)rot;
    /* The pointer lives in its own coordinate space, which on foldables does
     * not match what the app reports (wm size overrides, cover/inner switch).
     * Clamp into both corners and read the hover stream: that gives the real
     * bounds, so the centre is correct on DeX and on the phone. */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(90 * 1000);
    int x1 = -1, y1 = -1;
    cmd_mouse_move(30000.0, 30000.0);
    usleep(90 * 1000);
    read_pointer(&x1, &y1);
    if (x1 <= 0 || y1 <= 0) {
        out("CENTER skipped (no pointer bounds)");
        return;
    }
    int tx = x1 / 2, ty = y1 / 2;
    cmd_mouse_move((tx - x1) / g_pointer_gain, (ty - y1) / g_pointer_gain);
    usleep(220 * 1000);
    int nx = -1, ny = -1;
    read_pointer(&nx, &ny);
    if (nx >= 0 && ny >= 0 && (abs(tx - nx) > 30 || abs(ty - ny) > 30)) {
        cmd_mouse_move((tx - nx) / g_pointer_gain, (ty - ny) / g_pointer_gain);
        usleep(180 * 1000);
        int fx = -1, fy = -1;
        read_pointer(&fx, &fy);
        if (fx >= 0 && fy >= 0) {
            nx = fx;
            ny = fy;
        }
    }
    out("CENTER(bounds %d,%d) -> %d,%d (target %d,%d)", x1, y1, nx, ny, tx, ty);
}
'''

src = src[:start] + new + src[end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("replaced", len(old), "->", len(new))
