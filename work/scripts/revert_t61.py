p = 'project/app/src/main/assets/gpminput.c'
s = open(p, encoding='utf-8').read()
block = '''    /* 补 BTN_TOUCH：只发 MT 帧时部分 App/InputReader 不把拖拽当触摸流（t61 实测 padtest 收不到） */
    if (g_touch_slot0 < 0) {
        g_touch_slot0 = 1;
        ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1);
        ev_syn(g_touch_panel);
    }
'''
print('found:', block in s)
s = s.replace(block, '', 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('reverted')
