p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()

old = '''                if (g_out_fd != STDOUT_FILENO) out("OK d %d %d %d", dd, dx, dy);'''
new = '''                if (g_out_fd != STDOUT_FILENO) {
                    /* 控制通道：立即按下（不必等主循环），保证后续 m 能看到 active */
                    drag_down(dd, dx, dy);
                    out("OK d %d %d %d", dd, dx, dy);
                }'''
assert old in s
s = s.replace(old, new, 1)

# shared_drag_poll: also ensure down when no pending move
old2 = '''    if (g_dsh->dx != 0 || g_dsh->dy != 0) {'''
new2 = '''    if (g_dsh->active && !g_drag.active) drag_down(g_dsh->disp, g_dsh->ox, g_dsh->oy);
    if (g_dsh->dx != 0 || g_dsh->dy != 0) {'''
assert old2 in s
s = s.replace(old2, new2, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched t66 down-immediate')
