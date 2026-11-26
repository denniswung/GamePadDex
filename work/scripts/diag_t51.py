p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
s = s.replace('    g_ctl_client = c;\n    g_ctl_linelen = 0;\n    out("CTL connected uid=0");',
              '    g_ctl_client = c;\n    g_ctl_linelen = 0;\n    out("CTL connected uid=0 fd=%d", c);')
s = s.replace('static void control_client_readable(void) {\n    if (g_ctl_client < 0) return;',
              'static void control_client_readable(void) {\n    if (g_ctl_client < 0) return;\n    out("CTL read fd=%d", g_ctl_client);')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('diag added')
