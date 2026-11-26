p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

old = '''            if (lrc < 0) {
                if (errno == EINTR) { if (g_quit) break; continue; }
                break;
            }
            if (lrc == 0) {
                if (control_pending()) control_service();
                continue;
            }'''
new = '''            /* 控制连接随时读（lrc==0 的超时路径也要服务，否则客户端数据没人读） */
            if (g_ctl_client >= 0) {
                struct pollfd cp;
                cp.fd = g_ctl_client; cp.events = POLLIN; cp.revents = 0;
                if (poll(&cp, 1, 0) > 0 && (cp.revents & (POLLIN | POLLHUP))) control_client_readable();
            }
            if (control_pending()) control_service();
            if (lrc < 0) {
                if (errno == EINTR) { if (g_quit) break; continue; }
                break;
            }
            if (lrc == 0) continue;'''
assert old in s
s = s.replace(old, new, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched outer ctl read')
