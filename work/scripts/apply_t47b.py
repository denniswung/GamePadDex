import re

p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

start = s.index('/* 读一次真实光标逻辑坐标')
end = s.index('static void cmd_center')
new = '''/* 读一次真实光标逻辑坐标（cursor_logical 内部跑 dumpsys input，约 25ms） */
static int pointer_read(int *x, int *y) {
    int d = -1, sp = 0, fx = 0, fw = 0;
    double rx = -1, ry = -1;
    int lx = -1, ly = -1;
    if (!cursor_logical(&lx, &ly, &d, &sp, &rx, &ry, &fx, &fw)) return 0;
    if (lx < 0 || ly < 0) return 0;
    *x = lx;
    *y = ly;
    return 1;
}

/* 绝对定位：闭环（v1.69）。旧实现开环用固定 effective_gain()=3.25，本机
 * pointer_speed=-1 实测 ~2.14，落点偏小 34%（P 400,1200 -> 264,796）。
 * 现在：c 读真实光标 -> 朝屏幕内部 REL 80px 实测增益 -> 最多 4 次修正到 <=8px，
 * 每步用实际位移更新增益（边缘被夹时也能自适应）；落点写回 mmap 共享锚点，
 * fork 出的 P 子进程结果对父进程 SWIPE/drag 起手可见。 */
static void pointer_goto(int tx, int ty, int maxX, int maxY) {
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    g_disp_w = maxX;
    g_disp_h = maxY;
    if (tx < 0) tx = 0;
    if (ty < 0) ty = 0;
    if (tx > maxX) tx = maxX;
    if (ty > maxY) ty = maxY;
    double gain = effective_gain();
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (goto)");
    }
    int cx = -1, cy = -1;
    int have = pointer_read(&cx, &cy);
    if (!have) {
        /* 光标不可见（刚重建/隐藏）：有界回到左上角，再读一次 */
        double totalX = -(double)maxX * 1.2 / gain;
        double totalY = -(double)maxY * 1.2 / gain;
        const int STEPS = 40;
        for (int i = 0; i < STEPS; i++) {
            cmd_mouse_move(totalX / STEPS, totalY / STEPS);
            usleep(4 * 1000);
        }
        usleep(40 * 1000);
        have = pointer_read(&cx, &cy);
    }
    if (!have) {
        cmd_mouse_move((double)tx / gain, (double)ty / gain);
        g_ptr_x = tx;
        g_ptr_y = ty;
        out("POSPTR %d,%d openloop gain=%.2f iters=0", tx, ty, gain);
        return;
    }
    /* 朝屏幕内部方向走 80px 测实际增益（贴边时向外走会被夹住，测出假增益） */
    double gx = gain, gy = gain;
    int bx = cx, by = cy, nx = cx, ny = cy;
    double mx0 = (cx < maxX / 2) ? 80.0 : -80.0;
    double my0 = (cy < maxY / 2) ? 80.0 : -80.0;
    cmd_mouse_move(mx0, my0);
    usleep(35 * 1000);
    if (pointer_read(&nx, &ny)) {
        double mx = (double)(nx - bx);
        double my = (double)(ny - by);
        if (fabs(mx) >= 8.0) gx = mx / mx0;
        if (fabs(my) >= 8.0) gy = my / my0;
    }
    if (!(gx > 0.3 && gx < 12.0)) gx = gain;
    if (!(gy > 0.3 && gy < 12.0)) gy = gain;
    int iters = 0;
    int ex = 0, ey = 0;
    for (int it = 0; it < 4; it++) {
        ex = tx - nx;
        ey = ty - ny;
        if (abs(ex) <= 8 && abs(ey) <= 8) break;
        double rx = (double)ex / gx;
        double ry = (double)ey / gy;
        cmd_mouse_move(rx, ry);
        usleep(35 * 1000);
        int nx2 = nx, ny2 = ny;
        if (!pointer_read(&nx2, &ny2)) break;
        /* 用本步实际位移更新增益（贴边被夹时也能自适应） */
        if (fabs(rx) >= 8.0) {
            double g2 = (double)(nx2 - nx) / rx;
            if (g2 > 0.3 && g2 < 12.0) gx = g2;
        }
        if (fabs(ry) >= 8.0) {
            double g2 = (double)(ny2 - ny) / ry;
            if (g2 > 0.3 && g2 < 12.0) gy = g2;
        }
        nx = nx2;
        ny = ny2;
        iters++;
    }
    ex = tx - nx;
    ey = ty - ny;
    g_ptr_x = nx;
    g_ptr_y = ny;
    out("POSPTR %d,%d closed gain=%.2f,%.2f final=%d,%d err=%d,%d iters=%d anchor=%d,%d",
        tx, ty, gx, gy, nx, ny, ex, ey, iters, g_ptr_x, g_ptr_y);
}

'''
s = s[:start] + new + s[end:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched2')
