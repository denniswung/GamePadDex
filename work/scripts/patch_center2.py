import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()
start = src.index("static void cmd_center(")
end = src.index("\n}\n", start) + 3

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    if (maxX <= 0) maxX = 904;
    if (maxY <= 0) maxY = 2316;
    int tx = maxX / 2, ty = maxY / 2;
    int x = -1, y = -1;
    read_pointer(&x, &y);
    if (x < 0 || y < 0) {
        out("CENTER pointer unknown, target %d,%d", tx, ty);
        return;
    }
    int sx = x, sy = y;
    double rx = (tx - x) / g_pointer_gain;
    double ry = (ty - y) / g_pointer_gain;
    move_display(rx, ry, rot);
    usleep(260 * 1000);
    int nx = -1, ny = -1;
    read_pointer(&nx, &ny);
    if (nx >= 0 && ny >= 0 && (abs(tx - nx) > 30 || abs(ty - ny) > 30)) {
        move_display((tx - nx) / g_pointer_gain, (ty - ny) / g_pointer_gain, rot);
        usleep(200 * 1000);
        int fx = -1, fy = -1;
        read_pointer(&fx, &fy);
        if (fx >= 0 && fy >= 0) {
            nx = fx;
            ny = fy;
        }
    }
    out("CENTER %d,%d -> %d,%d (target %d,%d)", sx, sy, nx, ny, tx, ty);
}
'''
src = src[:start] + new + src[end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
