import io
p = '/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c'
s = io.open(p, encoding='utf-8').read()
head = s.split('static void cmd_center')[0]
if 'g_top_pkg' in head:
    print('already')
else:
    s = s.replace('static double g_center_gain = 2.16;',
                  'static double g_center_gain = 2.16;\n/* 最近一次解析到的前台包名（杀应用用） */\nstatic char g_top_pkg[192];', 1)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('declared')
