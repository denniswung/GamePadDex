import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("static void cmd_center(int maxX, int maxY, int park, int rot) {")
end = s.index("static void cmd_wheel(", start)
new = '''/* 一次性居中：读真实指针位置 → 一步补到位（自适应增益，最多 4 次）。
 * 相对鼠标 + 指针加速下"猜增益"必然有偏差，所以这里做成闭环。 */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }

    double gain = 2.16;          /* 初始猜测；实测后修正 */
    int px = -1, py = -1;
    for (int i = 0; i < 4; i++) {
        read_pointer(&px, &py);
        if (px < 0) {            /* 读不到位置：退回"夹角 + 固定增益" */
            cmd_mouse_move(-30000.0, -30000.0);
            usleep(20 * 1000);
            cmd_mouse_move(tx / 2.16, ty / 2.16);
            out("CENTER(fallback 2.16, no pointer readout) -> %d,%d", tx, ty);
            return;
        }
        int dx = tx - px, dy = ty - py;
        if (abs(dx) <= 2 && abs(dy) <= 2) {
            out("CENTER(closed-loop) -> %d,%d from %d,%d (iter %d)", tx, ty, px, py, i);
            return;
        }
        int rx = (int)(dx / gain), ry = (int)(dy / gain);
        cmd_mouse_move((double)rx, (double)ry);
        usleep(18 * 1000);
        /* 用实际结果修正增益 */
        int nx2 = -1, ny2 = -1;
        read_pointer(&nx2, &ny2);
        if (nx2 >= 0 && rx != 0) {
            double g = (double)(nx2 - px) / (double)rx;
            if (g > 0.3 && g < 20.0) gain = g;
        }
        out("CENTER step %d: pos %d,%d -> move raw %d,%d (gain %.2f)", i, px, py, rx, ry, gain);
    }
    read_pointer(&px, &py);
    out("CENTER(done) target %d,%d arrived %d,%d", tx, ty, px, py);
}

'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
