p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# 1) out(): route to g_out_fd, only App channel EPIPE quits
old1 = '    ssize_t r = write(STDOUT_FILENO, buf, n);'
new1 = '''    int wfd = g_out_fd;
    ssize_t r = write(wfd, buf, n);'''
assert old1 in s
s = s.replace(old1, new1, 1)

old2 = '    if (r < 0 && (errno == EPIPE || errno == ECONNRESET)) g_quit = 1;'
new2 = '''    if (r < 0 && (errno == EPIPE || errno == ECONNRESET)) {
        /* 只有 App 通道断开才退出；控制通道断开不影响守护进程 */
        if (wfd == STDOUT_FILENO) g_quit = 1;
    }'''
assert old2 in s
s = s.replace(old2, new2, 1)

# 2) declare g_out_fd before out()
s = s.replace('void out(const char *fmt, ...) {', 'static int g_out_fd = STDOUT_FILENO;   /* out() 输出去向（控制通道临时切到它的 fd） */\n\nvoid out(const char *fmt, ...) {', 1)

# 3) replace old fork-based control functions (start .. int main)
start = s.index('/* ---------------------------------------------------------- root 控制通道')
end = s.index('int main(int argc, char **argv) {')
new_block = '''/* ---------------------------------------------------------- root 控制通道
 * 额外监听 /data/adb/gpm/gpmctl.sock：仅 root（socket 0600 + SO_PEERCRED uid==0），
 * 与 App 的 gpm.sock 并存；命令复用同一个 handle_line，语义完全一致。
 * 控制连接在父进程内处理（不 fork），鼠标/拖拽/手势状态与 App 通道共享；
 * 输出通过 g_out_fd 临时切到控制连接。flock 单实例仍只由父进程持有。
 * /data/adb/gpm/gpmctl.disabled 存在时不创建（禁用方式）。
 */
#define CTL_SOCK_PATH "/data/adb/gpm/gpmctl.sock"
#define CTL_DISABLED_PATH "/data/adb/gpm/gpmctl.disabled"

static int g_ctl_client = -1;
static char g_ctl_linebuf[256];
static size_t g_ctl_linelen = 0;

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

static void control_client_close(void) {
    if (g_ctl_client >= 0) close(g_ctl_client);
    g_ctl_client = -1;
    g_out_fd = STDOUT_FILENO;
    g_ctl_linelen = 0;
}

static void accept_control_client(void) {
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

static void control_client_readable(void) {
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
}

int main(int argc, char **argv) {'''
s = s[:start] + new_block + s[end:]

# 4) outer loop: serve control
old_outer = '''            if (ln > 1 && (lp[1].revents & POLLIN)) {
                spawn_control_session();
                if (!(lp[0].revents & POLLIN)) continue;
            }'''
new_outer = '''            if (g_ctl_client >= 0) {
                struct pollfd cp;
                cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
                if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            }
            if (ln > 1 && (lp[1].revents & POLLIN)) {
                accept_control_client();
                if (!(lp[0].revents & POLLIN)) continue;
            }'''
assert old_outer in s
s = s.replace(old_outer, new_outer, 1)

# 5) session loop: accept + read control
s = s.replace('''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            spawn_control_session();
        }''', '''        if (ctl_idx >= 0 && (pfd[ctl_idx].revents & POLLIN)) {
            accept_control_client();
        }
        if (g_ctl_client >= 0) {
            struct pollfd cp;
            cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
            if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
        }''', 1)

# 6) cleanup
s = s.replace('''    if (g_ctl_listen >= 0) close(g_ctl_listen);   /* 不 unlink：避免旧实例退出时把新实例的 socket 删掉 */''',
              '''    control_client_close();
    if (g_ctl_listen >= 0) close(g_ctl_listen);   /* 不 unlink：避免旧实例退出时把新实例的 socket 删掉 */''', 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched in-process ctl (fixed)')
