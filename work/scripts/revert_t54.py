p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# ---- 1) remove t51 diagnostics ----
s = s.replace('    out("CTL connected uid=0 fd=%d", c);', '    out("CTL connected uid=0");')
s = s.replace('    if (g_ctl_client < 0) return;\n    out("CTL read fd=%d", g_ctl_client);', '    if (g_ctl_client < 0) return;')

# ---- 2) restore t48 accept_control_client (extra connection refused) ----
start = s.index('static void accept_control_client(void) {')
end = s.index('static char g_ctl_in[2048];')
t48_accept = '''static void accept_control_client(void) {
    if (g_ctl_listen < 0) return;
    if (g_ctl_client >= 0) {
        int extra = accept(g_ctl_listen, NULL, NULL);
        if (extra >= 0) close(extra);
        return;
    }
    int c = accept(g_ctl_listen, NULL, NULL);
    if (c < 0) return;
    if (!peer_is_root(c)) {
        close(c);
        out("CTL reject uid!=0");
        return;
    }
    fcntl(c, F_SETFD, FD_CLOEXEC);
    g_ctl_client = c;
    g_ctl_linelen = 0;
    out("CTL connected uid=0");
}

'''
s = s[:start] + t48_accept + s[end:]

# ---- 3) restore t48 control_client_readable (single-shot, close after processing) ----
start = s.index('static char g_ctl_in[2048];')
end = s.index('int main(int argc, char **argv) {')
t48_read = '''static void control_client_readable(void) {
    if (g_ctl_client < 0) return;
    char tmp[512];
    ssize_t rd = read(g_ctl_client, tmp, sizeof(tmp));
    if (rd <= 0) {
        if (rd == 0 && g_ctl_linelen > 0) {
            g_ctl_linebuf[g_ctl_linelen] = '\\0';
            g_out_fd = g_ctl_client;
            handle_line(g_ctl_linebuf);
            g_out_fd = STDOUT_FILENO;
            g_ctl_linelen = 0;
        }
        control_client_close();
        return;
    }
    for (ssize_t i = 0; i < rd; i++) {
        char c = tmp[i];
        if (c == '\\n' || c == '\\r') {
            g_ctl_linebuf[g_ctl_linelen] = '\\0';
            if (g_ctl_linelen > 0) {
                g_out_fd = g_ctl_client;
                handle_line(g_ctl_linebuf);
                g_out_fd = STDOUT_FILENO;
            }
            g_ctl_linelen = 0;
        } else if (g_ctl_linelen < sizeof(g_ctl_linebuf) - 1) {
            g_ctl_linebuf[g_ctl_linelen++] = c;
        }
    }
    /* 一次性客户端（sockcmd）发完就等 EOF：处理完本批命令后关闭连接 */
    control_client_close();
}

int main(int argc, char **argv) {'''
s = s[:start] + t48_read + s[end:]

# ---- 4) restore case 'e' (no drain loop) ----
old_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            /* 把排队中的拖拽帧发完再抬起：d/m/e 紧凑下发（或分连接）时 frames 不被吞 */
            for (int i = 0; i < 400 && g_drag.active && g_drag.steps_left > 0; i++) {
                drag_tick();
                if (g_drag.steps_left > 0) usleep((useconds_t)(g_drag.step_ms * 1000));
            }
            drag_release("cmd-e");
            break;'''
new_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            drag_release("cmd-e");
            break;'''
assert old_e in s, 'e drain block missing'
s = s.replace(old_e, new_e, 1)

# ---- 5) session loop: drop control_service call ----
old_sess = '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            accept_control_client();
        }
        if (g_ctl_client >= 0) {
            struct pollfd cp;
            cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
            if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            control_service();   /* 每轮最多一条，保证 drag 帧有机会发射 */
        }'''
new_sess = '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            accept_control_client();
        }
        if (g_ctl_client >= 0) {
            struct pollfd cp;
            cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
            if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
        }'''
assert old_sess in s, 'session ctl block missing'
s = s.replace(old_sess, new_sess, 1)

# ---- 6) outer loop: restore t48 structure (poll 500, no ctl client servicing) ----
start = s.index('            /* 绛?App 杩炴帴锛涙湡闂翠篃瑕佹湇鍔℃帶鍒堕€氶亾涓庢嫋鎷?鎵嬪娍瀹氭椂鍣?') if '            /* 绛?App' in s else s.index('            /* 等 App 连接；期间也要服务控制通道与拖拽/手势定时器')
end = s.index('            int c = accept(g_listen, NULL, NULL);', start)
t48_outer = '''            struct pollfd lp[2];
            int ln = 0;
            lp[ln].fd = g_listen; lp[ln].events = POLLIN; lp[ln].revents = 0; ln++;
            if (g_ctl_listen >= 0) {
                lp[ln].fd = g_ctl_listen; lp[ln].events = POLLIN; lp[ln].revents = 0; ln++;
            }
            int lrc = poll(lp, ln, 500);
            if (lrc < 0) {
                if (errno == EINTR) { if (g_quit) break; continue; }
                break;
            }
            if (lrc == 0) continue;
            if (ln > 1 && (lp[1].revents & POLLIN)) {
                accept_control_client();
                if (!(lp[0].revents & POLLIN)) continue;
            }
            if (!(lp[0].revents & POLLIN)) continue;
'''
s = s[:start] + t48_outer + s[end:]

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('reverted to t48 (a88c544a target)')
