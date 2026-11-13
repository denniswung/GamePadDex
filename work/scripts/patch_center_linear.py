import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()
start = s.index("static void cmd_center(")
end = s.index("\n}\n", start) + 3
new = '''static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    /* pointer gain is ~2.16 display px per raw unit (probe-measured on both
     * axes); clamp into the corner, then jump once to the centre. */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(90 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    usleep(160 * 1000);
    out("CENTER(linear) -> target %d,%d", tx, ty);
}
'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
