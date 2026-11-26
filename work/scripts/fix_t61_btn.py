p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
old = '''    touch_frame(0, g_drag.tid, g_drag.x, g_drag.y);
    g_drag.active = 1;'''
new = '''    /* 补 BTN_TOUCH：只发 MT 帧时部分 App/InputReader 不把拖拽当触摸流（t61 实测 padtest 收不到） */
    if (g_touch_slot0 < 0) {
        g_touch_slot0 = 1;
        ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1);
        ev_syn(g_touch_panel);
    }
    touch_frame(0, g_drag.tid, g_drag.x, g_drag.y);
    g_drag.active = 1;'''
assert old in s
s = s.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('patched drag BTN_TOUCH')
