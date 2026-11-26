p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

old = '''    if (g_dsh->dx != 0 || g_dsh->dy != 0) {
        int dx = g_dsh->dx, dy = g_dsh->dy, ms = g_dsh->ms > 0 ? g_dsh->ms : 100;
        g_dsh->dx = g_dsh->dy = 0;
        if (!g_drag.active) drag_down(g_dsh->disp, g_dsh->ox, g_dsh->oy);
        drag_move(g_dsh->disp, dx, dy, ms);
        g_dsh->stamp = now;
    }'''
new = '''    if (g_dsh->dx != 0 || g_dsh->dy != 0) {
        /* 分块推进：每轮最多 20px，保证 m 的位移能被逐帧发完（≥20 帧且总位移足额） */
        int maxc = 20;
        int stepx = g_dsh->dx > maxc ? maxc : (g_dsh->dx < -maxc ? -maxc : g_dsh->dx);
        int stepy = g_dsh->dy > maxc ? maxc : (g_dsh->dy < -maxc ? -maxc : g_dsh->dy);
        if (stepx == 0 && stepy == 0) { stepx = g_dsh->dx; stepy = g_dsh->dy; }
        g_dsh->dx -= stepx;
        g_dsh->dy -= stepy;
        if (!g_drag.active) drag_down(g_dsh->disp, g_dsh->ox, g_dsh->oy);
        drag_move(g_dsh->disp, stepx, stepy, 16);
        g_dsh->stamp = now;
    }'''
assert old in s
s = s.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched chunked drag')
