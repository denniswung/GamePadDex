import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
start = s.index("/* 居中：夹角 + 2.16 增益")
end = s.index("static void cmd_wheel(", start)
new = '''/* 居中：闭环。读真实指针位置 → 按估算增益补差 → 再读 → 最多 5 轮。
 * 绝不使用"超大位移夹角"：这台设备的指针不会被夹在屏幕内，
 * 一次 -30000 就把光标甩到屏幕外，用户看到的就是"光标消失了/居中不了"。 */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2316;
    if (maxY <= 0) maxY = 904;
    int tx = maxX / 2, ty = maxY / 2;

    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }

    int px = -1, py = -1;
    read_pointer(&px, &py);
    if (px < 0) {
        out("CENTER(skip: no pointer readout) -> %d,%d", tx, ty);
        return;
    }
    double gain = 2.16;
    for (int i = 0; i < 5; i++) {
        int dx = tx - px, dy = ty - py;
        if (abs(dx) <= 3 && abs(dy) <= 3) {
            out("CENTER(ok) %d,%d after %d step(s)", px, py, i);
            return;
        }
        int rx = (int)((double)dx / gain);
        int ry = (int)((double)dy / gain);
        if (rx == 0 && dx != 0) rx = dx > 0 ? 1 : -1;
        if (ry == 0 && dy != 0) ry = dy > 0 ? 1 : -1;
        cmd_mouse_move((double)rx, (double)ry);
        usleep(25 * 1000);
        int nx = -1, ny = -1;
        read_pointer(&nx, &ny);
        if (nx < 0) { out("CENTER(lost readout after step %d)", i); return; }
        if (rx != 0) {
            double g = (double)(nx - px) / (double)rx;
            if (g > 0.3 && g < 20.0) gain = g;
        }
        out("CENTER step %d: %d,%d -> raw %d,%d (gain %.2f)", i, px, py, rx, ry, gain);
        px = nx; py = ny;
    }
    out("CENTER(done) at %d,%d target %d,%d", px, py, tx, ty);
}

'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
