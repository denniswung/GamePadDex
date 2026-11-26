p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# ---- A) shared drag struct next to the pointer anchor ----
s = s.replace('''static int g_ptr_fallback[2] = {-1, -1};''', '''/* 拖拽共享状态：控制通道（root）与 App 通道共用；d/m/e 只更新这里，帧由主循环发 */
struct gpm_drag_sh {
    volatile int active;      /* 1 = 已按下 */
    volatile int disp;
    volatile int ox, oy;      /* 按下点 */
    volatile int dx, dy;      /* 待处理位移（m 累加） */
    volatile int ms;
    volatile int release;     /* e 请求 */
    volatile long long stamp;
};
static struct gpm_drag_sh *g_dsh = NULL;
static long long now_ms(void);
static int g_ptr_fallback[2] = {-1, -1};''', 1)

# ---- B) mmap: extend page to hold pointer + drag state ----
old_mmap = '''    void *ptr_sh = mmap(NULL, 2 * sizeof(int), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (ptr_sh != MAP_FAILED) {
        g_ptr_shared = (int *)ptr_sh;
        g_ptr_shared[0] = -1;
        g_ptr_shared[1] = -1;
    }'''
new_mmap = '''    size_t sh_size = 2 * sizeof(int) + sizeof(struct gpm_drag_sh);
    void *ptr_sh = mmap(NULL, sh_size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (ptr_sh != MAP_FAILED) {
        g_ptr_shared = (int *)ptr_sh;
        g_ptr_shared[0] = -1;
        g_ptr_shared[1] = -1;
        g_dsh = (struct gpm_drag_sh *)((char *)ptr_sh + 2 * sizeof(int));
        memset((void *)g_dsh, 0, sizeof(struct gpm_drag_sh));
    }'''
assert old_mmap in s
s = s.replace(old_mmap, new_mmap, 1)

# ---- C) d/m/e handlers: update shared state only ----
old_d = '''            int dd = 0, dx = 0, dy = 0;
            if (sscanf(line, "%d %d %d", &dd, &dx, &dy) == 3) drag_down(dd, dx, dy);
            else out("ERR d args");
            break;'''
new_d = '''            int dd = 0, dx = 0, dy = 0;
            if (sscanf(line, "%d %d %d", &dd, &dx, &dy) == 3) {
                if (g_dsh) {
                    g_dsh->disp = dd;
                    g_dsh->ox = dx;
                    g_dsh->oy = dy;
                    g_dsh->dx = g_dsh->dy = 0;
                    g_dsh->ms = 0;
                    g_dsh->release = 0;
                    g_dsh->stamp = now_ms();
                    g_dsh->active = 1;
                } else {
                    drag_down(dd, dx, dy);
                }
            } else out("ERR d args");
            break;'''
assert old_d in s
s = s.replace(old_d, new_d, 1)

old_m = '''            int dd = 0, dx = 0, dy = 0, ms = 0;
            if (sscanf(line, "%d %d %d %d", &dd, &dx, &dy, &ms) == 4) drag_move(dd, dx, dy, ms);
            else out("ERR m args");
            break;'''
new_m = '''            int dd = 0, dx = 0, dy = 0, ms = 0;
            if (sscanf(line, "%d %d %d %d", &dd, &dx, &dy, &ms) == 4) {
                if (g_dsh) {
                    g_dsh->dx += dx;
                    g_dsh->dy += dy;
                    g_dsh->ms = ms;
                    g_dsh->stamp = now_ms();
                    g_dsh->release = 0;
                } else {
                    drag_move(dd, dx, dy, ms);
                }
            } else out("ERR m args");
            break;'''
assert old_m in s
s = s.replace(old_m, new_m, 1)

old_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            drag_release("cmd-e");
            break;'''
new_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            if (g_dsh && g_dsh->active) {
                g_dsh->release = 1;
                g_dsh->stamp = now_ms();
            } else {
                drag_release("cmd-e");
            }
            break;'''
assert old_e in s
s = s.replace(old_e, new_e, 1)

# ---- D) main loop driver: apply shared state -> drag_move/down/release, frames by drag_tick ----
driver = '''/* 共享拖拽状态 -> 实际 drag 状态机；帧仍由主循环的 drag_tick() 发 */
static void shared_drag_poll(void) {
    if (!g_dsh || !g_dsh->active) return;
    long long now = now_ms();
    if (g_dsh->release) {
        if (!g_drag.active) drag_down(g_dsh->disp, g_dsh->ox, g_dsh->oy);
        /* 把剩余帧发完再抬起 */
        for (int i = 0; i < 400 && g_drag.active && g_drag.steps_left > 0; i++) {
            drag_tick();
            if (g_drag.steps_left > 0) usleep((useconds_t)(g_drag.step_ms * 1000));
        }
        drag_release("cmd-e");
        g_dsh->release = 0;
        g_dsh->active = 0;
        g_dsh->dx = g_dsh->dy = 0;
        g_dsh->ms = 0;
        return;
    }
    if (g_dsh->dx != 0 || g_dsh->dy != 0) {
        int dx = g_dsh->dx, dy = g_dsh->dy, ms = g_dsh->ms > 0 ? g_dsh->ms : 100;
        g_dsh->dx = g_dsh->dy = 0;
        if (!g_drag.active) drag_down(g_dsh->disp, g_dsh->ox, g_dsh->oy);
        drag_move(g_dsh->disp, dx, dy, ms);
        g_dsh->stamp = now;
    }
    if (!g_drag.active && now - g_dsh->stamp > 1500) {
        g_dsh->active = 0;   /* 1.5s 无 m：auto-up 由 drag_tick 完成 */
    }
}

int main(int argc, char **argv) {'''
s = s.replace('int main(int argc, char **argv) {', driver, 1)

# ---- E) session loop: call driver + short timeout while shared drag active ----
s = s.replace('''        long long next_drag = drag_tick();
        int n = 0;''', '''        shared_drag_poll();
        long long next_drag = drag_tick();
        if (g_dsh && g_dsh->active) next_drag = next_drag < 0 ? 8 : (next_drag > 8 ? 8 : next_drag);
        int n = 0;''', 1)

# ---- F) outer loop: run driver + drag_tick with 8ms cadence (detached drag, no app client) ----
s = s.replace('''            struct pollfd lp[2];
            int ln = 0;''', '''            shared_drag_poll();
            long long o_next_drag = drag_tick();
            int o_timeout = (g_dsh && g_dsh->active) ? 8 : 200;
            if (o_next_drag >= 0 && o_next_drag < o_timeout) o_timeout = o_next_drag <= 0 ? 1 : (int)o_next_drag;
            struct pollfd lp[2];
            int ln = 0;''', 1)
s = s.replace('''            int lrc = poll(lp, ln, 500);
            if (lrc < 0) {''', '''            int lrc = poll(lp, ln, o_timeout);
            if (lrc < 0) {''', 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched t54')
