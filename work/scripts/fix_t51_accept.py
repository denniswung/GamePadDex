p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
old = '''static void accept_control_client(void) {
    if (g_ctl_listen < 0) return;
    if (g_ctl_client >= 0) {
        /* 同一时刻只服务一个控制连接；多余连接直接关掉 */
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
}'''
new = '''static void accept_control_client(void) {
    if (g_ctl_listen < 0) return;
    int c = accept(g_ctl_listen, NULL, NULL);
    if (c < 0) return;
    if (!peer_is_root(c)) {
        close(c);
        out("CTL reject uid!=0");
        return;
    }
    /* 新连接替换旧连接（旧连接可能已死/卡住，避免一次性客户端被“多余连接”拒掉） */
    if (g_ctl_client >= 0) close(g_ctl_client);
    g_ctl_in_len = 0;
    fcntl(c, F_SETFD, FD_CLOEXEC);
    g_ctl_client = c;
    g_ctl_linelen = 0;
    out("CTL connected uid=0");
}'''
assert old in s, 'accept_control_client missing'
s = s.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched accept replace')
