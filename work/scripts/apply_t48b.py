p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

old_ctl = '''            ssize_t rd = read(STDIN_FILENO, tmp, sizeof(tmp));
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
    drag_release("ctl session end");'''

new_ctl = '''            ssize_t rd = read(STDIN_FILENO, tmp, sizeof(tmp));
            if (rd <= 0) {
                /* EOF 前没有换行（sockcmd 这类一次性客户端）：把残留当一条命令 */
                if (rd == 0 && linelen > 0) {
                    linebuf[linelen] = '\\0';
                    handle_line(linebuf);
                    linelen = 0;
                }
                break;
            }
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
    drag_release("ctl session end");'''

assert old_ctl in s, 'ctl block not found'
s = s.replace(old_ctl, new_ctl, 1)

old_app = '''            char tmp[512];
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

        for (int i = 0; i < g_ndev; i++) {'''

new_app = '''            char tmp[512];
            ssize_t rd = read(STDIN_FILENO, tmp, sizeof(tmp));
            if (rd <= 0) {
                if (rd == 0 && linelen > 0) {
                    linebuf[linelen] = '\\0';
                    handle_line(linebuf);
                    linelen = 0;
                }
                break;
            }
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

        for (int i = 0; i < g_ndev; i++) {'''

assert old_app in s, 'app block not found'
s = s.replace(old_app, new_app, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched eof flush')
