import sys, io

p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
start = s.index("static void cmd_center(")
end = s.index("\n}\n", start) + 3

new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    /* The kernel pointer acceleration is NOT linear: a single raw delta d
     * moves the cursor by  a*d + b*d*d  pixels.  Measured on SM-F9360:
     *   d=394 -> 849 px, d=711 -> 2309 px  =>  a=0.794, b=0.00345.
     * Clamp into the corner first, then jump with the inverted model. */
    const double a = 0.794, b = 0.00345;
    double rx = (-a + sqrt(a * a + 4.0 * b * tx)) / (2.0 * b);
    double ry = (-a + sqrt(a * a + 4.0 * b * ty)) / (2.0 * b);
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(90 * 1000);
    cmd_mouse_move(rx, ry);
    usleep(160 * 1000);
    out("CENTER(model) -> target %d,%d (raw %.0f,%.0f)", tx, ty, rx, ry);
}
'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
