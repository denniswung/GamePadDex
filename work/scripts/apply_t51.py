p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# ---------- 1) buffered control input + one-line-per-service ----------
start = s.index('static void control_client_readable(void) {')
end = s.index('int main(int argc, char **argv) {')
new_ctl = '''static char g_ctl_in[2048];
static size_t g_ctl_in_len = 0;

static void control_client_readable(void) {
    if (g_ctl_client < 0) return;
    if (g_ctl_in_len >= sizeof(g_ctl_in) - 1) g_ctl_in_len = 0;   /* 防溢出：丢旧数据 */
    char tmp[512];
    ssize_t rd = read(g_ctl_client, tmp, sizeof(tmp));
    if (rd <= 0) {
        /* EOF：把缓冲区里最后一个没有换行的命令执行掉，然后关闭 */
        if (rd == 0 && g_ctl_in_len > 0) {
            size_t n = g_ctl_in_len;
            while (n > 0 && (g_ctl_in[n - 1] == '\\n' || g_ctl_in[n - 1] == '\\r')) n--;
            if (n > 0) {
                if (n > sizeof(g_ctl_linebuf) - 1) n = sizeof(g_ctl_linebuf) - 1;
                memcpy(g_ctl_linebuf, g_ctl_in, n);
                g_ctl_linebuf[n] = '\\0';
                g_out_fd = g_ctl_client;
                handle_line(g_ctl_linebuf);
                g_out_fd = STDOUT_FILENO;
            }
        }
        g_ctl_in_len = 0;
        control_client_close();
        return;
    }
    if (g_ctl_in_len + (size_t)rd >= sizeof(g_ctl_in)) {
        g_ctl_in_len = 0;
        if ((size_t)rd >= sizeof(g_ctl_in)) rd = sizeof(g_ctl_in) - 1;
    }
    memcpy(g_ctl_in + g_ctl_in_len, tmp, (size_t)rd);
    g_ctl_in_len += (size_t)rd;
}

/* 缓冲区里是否还有完整的一行（供主循环每轮处理一条，不阻塞） */
static int control_pending(void) {
    for (size_t i = 0; i < g_ctl_in_len; i++) {
        if (g_ctl_in[i] == '\\n' || g_ctl_in[i] == '\\r') return 1;
    }
    return 0;
}

/* 每轮只处理一条命令：保证 m 之后主循环还能跑 drag_tick 发帧 */
static int control_service(void) {
    if (g_ctl_client < 0) return 0;
    size_t cut = (size_t)-1;
    for (size_t i = 0; i < g_ctl_in_len; i++) {
        if (g_ctl_in[i] == '\\n' || g_ctl_in[i] == '\\r') { cut = i; break; }
    }
    if (cut == (size_t)-1) return 0;
    size_t n = cut;
    if (n > sizeof(g_ctl_linebuf) - 1) n = sizeof(g_ctl_linebuf) - 1;
    memcpy(g_ctl_linebuf, g_ctl_in, n);
    g_ctl_linebuf[n] = '\\0';
    size_t consumed = cut + 1;
    while (consumed < g_ctl_in_len && (g_ctl_in[consumed] == '\\n' || g_ctl_in[consumed] == '\\r')) consumed++;
    memmove(g_ctl_in, g_ctl_in + consumed, g_ctl_in_len - consumed);
    g_ctl_in_len -= consumed;
    if (n > 0) {
        g_out_fd = g_ctl_client;
        handle_line(g_ctl_linebuf);
        g_out_fd = STDOUT_FILENO;
    }
    return 1;
}

int main(int argc, char **argv) {'''
s = s[:start] + new_ctl + s[end:]

# ---------- 2) e: drain pending drag frames before releasing ----------
old_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            drag_release("cmd-e");
            break;'''
new_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            /* 把排队中的拖拽帧发完再抬起：d/m/e 紧凑下发（或分连接）时 frames 不被吞 */
            for (int i = 0; i < 400 && g_drag.active && g_drag.steps_left > 0; i++) {
                drag_tick();
                if (g_drag.steps_left > 0) usleep((useconds_t)(g_drag.step_ms * 1000));
            }
            drag_release("cmd-e");
            break;'''
assert old_e in s, 'e handler missing'
s = s.replace(old_e, new_e, 1)

# ---------- 3) session loop: service one control line per iteration ----------
old_sess = '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            accept_control_client();
        }
        if (g_ctl_client >= 0) {
            struct pollfd cp;
            cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
            if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
        }'''
new_sess = '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            accept_control_client();
        }
        if (g_ctl_client >= 0) {
            struct pollfd cp;
            cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
            if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            control_service();   /* 每轮最多一条，保证 drag 帧有机会发射 */
        }'''
assert old_sess in s, 'session ctl block missing'
s = s.replace(old_sess, new_sess, 1)

# ---------- 4) outer loop: timers + control service (detached drag without app client) ----------
old_outer = '''    while (!g_quit) {
        if (g_listen >= 0) {
            /* 等 App 连接；期间也要服务控制通道 */
            struct pollfd lp[2];
            int ln = 0;'''
new_outer = '''    while (!g_quit) {
        if (g_listen >= 0) {
            /* 等 App 连接；期间也要服务控制通道与拖拽/手势定时器
             * （detached drag：引擎未连接时 d/m/e 也要能发帧） */
            long long o_next_key = key_release_due();
            gesture_poll();
            long long o_next_drag = drag_tick();
            int o_timeout = g_pinch_dir != 0 ? 8 : gesture_poll_timeout();
            if (o_next_key >= 0 && o_next_key < o_timeout) o_timeout = o_next_key <= 0 ? 1 : (int)o_next_key;
            if (o_next_drag >= 0 && o_next_drag < o_timeout) o_timeout = o_next_drag <= 0 ? 1 : (int)o_next_drag;
            if (control_pending()) o_timeout = 1;
            /* 等 App 连接；期间也要服务控制通道 */
            struct pollfd lp[2];
            int ln = 0;'''
assert old_outer in s, 'outer loop header missing'
s = s.replace(old_outer, new_outer, 1)

old_poll = '''            int lrc = poll(lp, ln, 500);
            if (lrc < 0) {
                if (errno == EINTR) { if (g_quit) break; continue; }
                break;
            }
            if (lrc == 0) continue;
            if (g_ctl_client >= 0) {
                struct pollfd cp;
                cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
                if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            }'''
new_poll = '''            int lrc = poll(lp, ln, o_timeout);
            reap_children();
            gesture_poll();
            key_release_due();
            drag_tick();
            pinch_tick();
            if (lrc < 0) {
                if (errno == EINTR) { if (g_quit) break; continue; }
                break;
            }
            if (lrc == 0) {
                if (control_pending()) control_service();
                continue;
            }
            if (g_ctl_client >= 0) {
                struct pollfd cp;
                cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
                if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            }
            if (control_pending()) control_service();'''
assert old_poll in s, 'outer poll block missing'
s = s.replace(old_poll, new_poll, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched t51')
