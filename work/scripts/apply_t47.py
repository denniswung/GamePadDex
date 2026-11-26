import re

p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# 1) include mman
s = s.replace('#include <sys/ioctl.h>\n', '#include <sys/ioctl.h>\n#include <sys/mman.h>\n', 1)

# 2) shared anchor declarations near top (after g_touch_panel)
s = s.replace('static int g_touch_panel = -1;\n',
              'static int g_touch_panel = -1;\n'
              'static int g_ptr_fallback[2] = {-1, -1};\n'
              'static int *g_ptr_shared = g_ptr_fallback;   /* [0]=x [1]=y；main 里换成 mmap 共享页，P 子进程落点父进程可见 */\n'
              '#define g_ptr_x (g_ptr_shared[0])\n'
              '#define g_ptr_y (g_ptr_shared[1])\n', 1)

# 3) remove the old plain anchor declaration
s = s.replace('static int g_ptr_x = -1, g_ptr_y = -1;\n', '', 1)

# 4) replace pointer_goto with pointer_read + closed loop
old_start = s.index('static void pointer_goto(int tx, int ty, int maxX, int maxY) {')
old_end = s.index('static void cmd_center')
new_block = '''/* 读一次真实光标逻辑坐标（cursor_logical 内部跑 dumpsys input，约 25ms） */
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
 * 现在：c 读真实光标 -> REL 80px 实测增益 -> 最多 4 次修正到 <=8px；
 * 落点写回共享锚点（mmap 共享页），fork 出的 P 子进程结果对父进程 SWIPE/drag 可见。 */
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
    double gx = gain, gy = gain;
    int bx = cx, by = cy, nx = cx, ny = cy;
    cmd_mouse_move(80.0, 80.0);
    usleep(35 * 1000);
    if (pointer_read(&nx, &ny)) {
        double mx = (double)(nx - bx);
        double my = (double)(ny - by);
        if (fabs(mx) >= 8.0 && fabs(mx) <= 80.0 * 12.0) gx = mx / 80.0;
        if (fabs(my) >= 8.0 && fabs(my) <= 80.0 * 12.0) gy = my / 80.0;
    }
    if (gx < 0.5 || gx > 12.0) gx = gain;
    if (gy < 0.5 || gy > 12.0) gy = gain;
    int iters = 0;
    int ex = 0, ey = 0;
    for (int it = 0; it < 4; it++) {
        ex = tx - nx;
        ey = ty - ny;
        if (abs(ex) <= 8 && abs(ey) <= 8) break;
        cmd_mouse_move((double)ex / gx, (double)ey / gy);
        usleep(35 * 1000);
        int nx2 = nx, ny2 = ny;
        if (!pointer_read(&nx2, &ny2)) break;
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
s = s[:old_start] + new_block + s[old_end:]

# 5) mmap shared page in main
s = s.replace('''    g_ino_fd = inotify_init1(IN_NONBLOCK);''',
              '''    void *ptr_sh = mmap(NULL, 2 * sizeof(int), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (ptr_sh != MAP_FAILED) {
        g_ptr_shared = (int *)ptr_sh;
        g_ptr_shared[0] = -1;
        g_ptr_shared[1] = -1;
    }
    g_ino_fd = inotify_init1(IN_NONBLOCK);''', 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched, length', len(s))
