p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
old = '''        } else if (g_ctl_linelen < sizeof(g_ctl_linebuf) - 1) {
            g_ctl_linelen++;
        }
    }
}'''
# find the actual end of control_client_readable by locating its last lines
idx = s.index('static void control_client_readable(void) {')
seg = s[idx:idx + 4000]
# append close after the byte loop: insert before the function's closing "}\n"
marker = '''        } else if (g_ctl_linelen < sizeof(g_ctl_linebuf) - 1) {
            g_ctl_linebuf[g_ctl_linelen++] = c;
        }
    }
}'''
new_marker = '''        } else if (g_ctl_linelen < sizeof(g_ctl_linebuf) - 1) {
            g_ctl_linebuf[g_ctl_linelen++] = c;
        }
    }
    /* 一次性客户端（sockcmd）发完就等 EOF：处理完本批命令后关闭连接 */
    control_client_close();
}'''
assert marker in s, 'marker missing'
s = s.replace(marker, new_marker, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched one-shot close')
