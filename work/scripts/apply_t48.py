import re

p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# 1) global ctl listen fd
s = s.replace('static int g_listen = -1;\n', 'static int g_listen = -1;\nstatic int g_ctl_listen = -1;   /* 仅 root 的诊断控制通道 */\n', 1)

# 2) control channel functions, inserted before "int main("
ctl = '''/* ---------------------------------------------------------- root 控制通道
 * 额外监听 /data/adb/gpm/gpmctl.sock：仅 root（socket 0600 + SO_PEERCRED uid==0），
 * 与 App 的 gpm.sock 并存；命令复用同一个 handle_line，语义完全一致。
 * /data/adb/gpm/gpmctl.disabled 存在时不创建（禁用方式）。
 * 控制连接在 fork 出的子进程里跑独立会话：不影响 App 会话的 fd/状态；
 * flock 单实例仍只由父进程持有。
 */
#define CTL_SOCK_PATH "/data/adb/gpm/gpmctl.sock"
#define CTL_DISABLED_PATH "/data/adb/gpm/gpmctl.disabled"

static int peer_is_root(int fd) {
    struct ucred cr;
    socklen_t len = sizeof(cr);
    memset(&cr, 0, sizeof(cr));
    if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &cr, &len) != 0) return 0;
    return cr.uid == 0;
}

static void setup_control_socket(void) {
    if (access(CTL_DISABLED_PATH, F_OK) == 0) {
        out("CTL disabled (%s)", CTL_DISABLED_PATH);
        return;
    }
    int sfd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
    if (sfd < 0) return;
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s", CTL_SOCK_PATH);
    unlink(CTL_SOCK_PATH);
    if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(sfd);
        return;
    }
    chmod(CTL_SOCK_PATH, 0600);
    chown(CTL_SOCK_PATH, 0, 0);
    chmod("/data/adb/gpm", 0700);
    if (listen(sfd, 4) < 0) {
        close(sfd);
        unlink(CTL_SOCK_PATH);
        return;
    }
    g_ctl_listen = sfd;
    out("CTL listening %s", CTL_SOCK_PATH);
}

/* 控制连接会话：与 App 会话相同的读行 + 定时器（drag/gesture/key release） */
static void run_control_session(int fd) {
    if (fd < 0) return;
    dup2(fd, STDIN_FILENO);
    dup2(fd, STDOUT_FILENO);
    close(fd);
    fcntl(STDIN_FILENO, F_SETFD, FD_CLOEXEC);
    char linebuf[256];
    size_t linelen = 0;
    while (!g_quit) {
        long long next_key = key_release_due();
        gesture_poll();
        long long next_drag = drag_tick();
        int timeout = g_pinch_dir != 0 ? 8 : gesture_poll_timeout();
        if (next_key >= 0 && next_key < timeout) timeout = next_key <= 0 ? 1 : (int)next_key;
        if (next_drag >= 0 && next_drag < timeout) timeout = next_drag <= 0 ? 1 : (int)next_drag;
        struct pollfd pf;
        pf.fd = STDIN_FILENO;
        pf.events = POLLIN;
        pf.revents = 0;
        int rc = poll(&pf, 1, timeout);
        reap_children();
        gesture_poll();
        key_release_due();
        drag_tick();
        pinch_tick();
        if (rc < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (rc == 0) { pinch_tick(); continue; }
        if (pf.revents & (POLLIN | POLLHUP)) {
            char tmp[512];
            ssize_t rd = read(STDIN_FILENO, tmp, sizeof(tmp));
            if (rd <= 0) break;
            for (ssize_t i = 0; i < rd; i++) {
                char c = tmp[i];
                if (c == '\\n' || c == '\\r') {
                    linebuf[linelen] = '\\0';
                    handle_line(linebuf);
                    linelen = 0;
                } else if (linelen < sizeof(linebuf) - 1) {
                    linebuf[linelen++] = c;
                }
            }
        }
    }
    drag_release("ctl session end");
    key_release_all();
}

/* 接受一条控制连接：非 root 直接拒绝；root 则 fork 独立会话 */
static void spawn_control_session(void) {
    int c = accept(g_ctl_listen, NULL, NULL);
    if (c < 0) return;
    if (!peer_is_root(c)) {
        out("CTL reject uid!=0");
        close(c);
        return;
    }
    pid_t pid = fork();
    if (pid == 0) {
        if (g_listen >= 0) close(g_listen);
        if (g_ctl_listen >= 0) close(g_ctl_listen);
        run_control_session(c);
        _exit(0);
    }
    close(c);
}

int main(int argc, char **argv) {'''
s = s.replace('int main(int argc, char **argv) {', ctl, 1)

# 3) create control socket in socket mode
s = s.replace('''        setup_socket(argv[2]);''', '''        setup_socket(argv[2]);
        setup_control_socket();''', 1)

# 4) outer accept loop: wait on app or control
old_outer = '''    while (!g_quit) {
        if (g_listen >= 0) {
            int c = accept(g_listen, NULL, NULL);
            if (c < 0) {
                if (errno == EINTR) {
                    if (g_quit) break;
                    continue;
                }
                break;
            }'''
new_outer = '''    while (!g_quit) {
        if (g_listen >= 0) {
            /* 等 App 连接；期间也要服务控制通道 */
            struct pollfd lp[2];
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
                spawn_control_session();
                if (!(lp[0].revents & POLLIN)) continue;
            }
            if (!(lp[0].revents & POLLIN)) continue;
            int c = accept(g_listen, NULL, NULL);
            if (c < 0) {
                if (errno == EINTR) {
                    if (g_quit) break;
                    continue;
                }
                break;
            }'''
s = s.replace(old_outer, new_outer, 1)

# 5) session loop: serve control connections too (append after inotify slot)
s = s.replace('''        int ino_idx = -1;
        if (g_ino_fd >= 0) {
            ino_idx = n;
            pfd[n].fd = g_ino_fd;
            pfd[n].events = POLLIN;
            n++;
        }''', '''        int ino_idx = -1;
        if (g_ino_fd >= 0) {
            ino_idx = n;
            pfd[n].fd = g_ino_fd;
            pfd[n].events = POLLIN;
            n++;
        }
        int ctl_idx = -1;
        if (g_ctl_listen >= 0) {
            ctl_idx = n;
            pfd[n].fd = g_ctl_listen;
            pfd[n].events = POLLIN;
            pfd[n].revents = 0;
            n++;
        }''', 1)

s = s.replace('''        if (ino_idx >= 0 && (pfd[ino_idx].revents & POLLIN)) {''', '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            spawn_control_session();
        }

        if (ino_idx >= 0 && (pfd[ino_idx].revents & POLLIN)) {''', 1)

# pfd array size +1
s = s.replace('struct pollfd pfd[1 + MAX_DEVS + 2];', 'struct pollfd pfd[1 + MAX_DEVS + 3];', 1)

# 6) cleanup: close/unlink control socket
s = s.replace('''    if (g_listen >= 0) close(g_listen);''', '''    if (g_listen >= 0) close(g_listen);
    if (g_ctl_listen >= 0) {
        close(g_ctl_listen);
        unlink(CTL_SOCK_PATH);
    }''', 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched ctl, length', len(s))
