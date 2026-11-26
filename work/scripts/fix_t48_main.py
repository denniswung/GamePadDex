p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
dup = "int main(int argc, char **argv) {\nint main(int argc, char **argv) {"
print('dup found:', dup in s)
s = s.replace(dup, "int main(int argc, char **argv) {", 1)
old = "    if (g_listen >= 0) close(g_listen);\n    if (g_mouse >= 0)"
new = ("    control_client_close();\n"
       "    if (g_listen >= 0) close(g_listen);\n"
       "    if (g_ctl_listen >= 0) close(g_ctl_listen);   /* 不 unlink：避免旧实例退出时把新实例的 socket 删掉 */\n"
       "    if (g_mouse >= 0)")
if old in s:
    s = s.replace(old, new, 1)
    print('cleanup patched')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('done')
