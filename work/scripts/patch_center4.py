import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()
start = src.index("static void cmd_center(")
end = src.index("\n}\n", start) + 3

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 904;
    if (maxY <= 0) maxY = 2316;
    int tx = maxX / 2, ty = maxY / 2;

    /* deterministic corner, then measure how raw units map to the pointer
     * space with two large probe moves (small probes are lost in rounding) */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(120 * 1000);
    int x0 = -1, y0 = -1;
    read_pointer(&x0, &y0);
    if (x0 < 0 || y0 < 0) {
        cmd_mouse_move((maxX / 2) / g_pointer_gain, (maxY / 2) / g_pointer_gain);
        usleep(150 * 1000);
        out("CENTER(corner) -> target %d,%d", tx, ty);
        return;
    }
    cmd_mouse_move(1500.0, 0.0);
    usleep(120 * 1000);
    int x1 = -1, y1 = -1;
    read_pointer(&x1, &y1);
    cmd_mouse_move(0.0, 1500.0);
    usleep(120 * 1000);
    int x2 = -1, y2 = -1;
    read_pointer(&x2, &y2);
    if (x1 < 0 || x2 < 0) {
        cmd_mouse_move((maxX / 2) / g_pointer_gain, (maxY / 2) / g_pointer_gain);
        usleep(150 * 1000);
        out("CENTER(corner) -> target %d,%d", tx, ty);
        return;
    }
    double ax = (x1 - x0) / 1500.0, ay = (y1 - y0) / 1500.0;
    double bx = (x2 - x1) / 1500.0, by = (y2 - y1) / 1500.0;
    double det = ax * by - ay * bx;
    int nx = x2, ny = y2;
    if (fabs(det) > 1e-9) {
        double dx = tx - x2, dy = ty - y2;
        double rx = (dx * by - dy * bx) / det;
        double ry = (-dx * ay + dy * ax) / det;
        cmd_mouse_move(rx, ry);
        usleep(150 * 1000);
        int fx = -1, fy = -1;
        read_pointer(&fx, &fy);
        if (fx >= 0 && fy >= 0) {
            nx = fx;
            ny = fy;
            if (abs(tx - nx) > 10 || abs(ty - ny) > 10) {
                dx = tx - nx;
                dy = ty - ny;
                rx = (dx * by - dy * bx) / det;
                ry = (-dx * ay + dy * ax) / det;
                cmd_mouse_move(rx, ry);
                usleep(120 * 1000);
                int gx = -1, gy = -1;
                read_pointer(&gx, &gy);
                if (gx >= 0 && gy >= 0) {
                    nx = gx;
                    ny = gy;
                }
            }
        }
    }
    out("CENTER(probe) -> %d,%d (target %d,%d)", nx, ny, tx, ty);
}
'''
src = src[:start] + new + src[end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
