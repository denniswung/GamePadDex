p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

# d
old_d = '''            int dd = 0, dx = 0, dy = 0;
            if (sscanf(line, "%d %d %d", &dd, &dx, &dy) == 3) {
                if (g_dsh) {
                    g_dsh->disp = dd;'''
new_d = '''            int dd = 0, dx = 0, dy = 0;
            if (sscanf(line, "%d %d %d", &dd, &dx, &dy) == 3) {
                if (g_out_fd != STDOUT_FILENO && g_drag.active) {
                    out("ERR_STATE d busy");
                    break;
                }
                if (g_dsh) {
                    g_dsh->disp = dd;'''
assert old_d in s
s = s.replace(old_d, new_d, 1)

old_d2 = '''                } else {
                    drag_down(dd, dx, dy);
                }
            } else out("ERR d args");
            break;'''
new_d2 = '''                } else {
                    drag_down(dd, dx, dy);
                }
                if (g_out_fd != STDOUT_FILENO) out("OK d %d %d %d", dd, dx, dy);
            } else {
                if (g_out_fd != STDOUT_FILENO) out("ERR_ARG d");
                else out("ERR d args");
            }
            break;'''
assert old_d2 in s
s = s.replace(old_d2, new_d2, 1)

# m
old_m = '''            int dd = 0, dx = 0, dy = 0, ms = 0;
            if (sscanf(line, "%d %d %d %d", &dd, &dx, &dy, &ms) == 4) {
                if (g_dsh) {'''
new_m = '''            int dd = 0, dx = 0, dy = 0, ms = 0;
            if (sscanf(line, "%d %d %d %d", &dd, &dx, &dy, &ms) == 4) {
                if (g_out_fd != STDOUT_FILENO && !(g_dsh && g_dsh->active)) {
                    out("ERR_STATE m no-down");
                    break;
                }
                if (g_dsh) {'''
assert old_m in s
s = s.replace(old_m, new_m, 1)

old_m2 = '''                } else {
                    drag_move(dd, dx, dy, ms);
                }
            } else out("ERR m args");
            break;'''
new_m2 = '''                } else {
                    drag_move(dd, dx, dy, ms);
                }
                if (g_out_fd != STDOUT_FILENO) out("OK m %d %d %d", dx, dy, ms);
            } else {
                if (g_out_fd != STDOUT_FILENO) out("ERR_ARG m");
                else out("ERR m args");
            }
            break;'''
assert old_m2 in s
s = s.replace(old_m2, new_m2, 1)

# e
old_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            if (g_dsh && g_dsh->active) {
                g_dsh->release = 1;
                g_dsh->stamp = now_ms();
            } else {
                drag_release("cmd-e");
            }
            break;'''
new_e = '''            int dd = 0;
            sscanf(line, "%d", &dd);
            if (g_dsh && g_dsh->active) {
                g_dsh->release = 1;
                g_dsh->stamp = now_ms();
                if (g_out_fd != STDOUT_FILENO) out("OK e");
            } else {
                drag_release("cmd-e");
                if (g_out_fd != STDOUT_FILENO) out("ERR_STATE e no-drag");
            }
            break;'''
assert old_e in s
s = s.replace(old_e, new_e, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched t66 replies')
