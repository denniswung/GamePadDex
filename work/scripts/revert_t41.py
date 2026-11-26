import re

p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

orig_pointer_goto = '''static void pointer_goto(int tx, int ty, int maxX, int maxY) {
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
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
}

'''

start = s.index('/* 读一次真实光标逻辑坐标')
end = s.index('static void cmd_center')
s = s[:start] + orig_pointer_goto + s[end:]

# restore plain anchor declaration
s = s.replace('''static int g_ptr_fallback[2] = {-1, -1};
static int *g_ptr_shared = g_ptr_fallback;   /* [0]=x [1]=y；main 里换成 mmap 共享页，P 子进程的落点父进程可见 */
#define g_ptr_x (g_ptr_shared[0])
#define g_ptr_y (g_ptr_shared[1])''', 'static int g_ptr_x = -1, g_ptr_y = -1;')

# remove mmap setup
s = s.replace('''    void *ptr_sh = mmap(NULL, 2 * sizeof(int), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (ptr_sh != MAP_FAILED) {
        g_ptr_shared = (int *)ptr_sh;
        g_ptr_shared[0] = -1;
        g_ptr_shared[1] = -1;
    }
''', '')

# remove mman include
s = s.replace('#include <sys/mman.h>\n', '')

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('reverted, length', len(s))
