import io
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 记录已知显示尺寸（cmd_center / pointer_goto 都会被告知）
rep("static double g_center_gain = 2.16;",
    "static double g_center_gain = 2.16;\n/* 最近一次已知的屏幕尺寸（通知栏下滑手势要用） */\nstatic int g_disp_w = 0, g_disp_h = 0;", "disp-vars")

rep('''static void pointer_goto(int tx, int ty, int maxX, int maxY) {
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;''',
    '''static void pointer_goto(int tx, int ty, int maxX, int maxY) {
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    g_disp_w = maxX;
    g_disp_h = maxY;''', "disp-cache")

# 通知栏：改成"从顶部边缘下滑"的真实触摸手势（uinput 的 KEY_NOTIFICATION_CENTER 在三星上不展开）
rep('''        case 'N': {
            /* cmd statusbar 在这个 SELinux 域里注入不了（rc=512），
             * 改走虚拟键盘的 KEY_NOTIFICATION_CENTER(444) → 系统映射成通知栏。 */
            int ok = 0;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, 444, 1);
                ev_syn(g_kbd);
                usleep(40 * 1000);
                ev_emit(g_kbd, EV_KEY, 444, 0);
                ev_syn(g_kbd);
                ok = 1;
            }
            out("NOTIF uinput=%d", ok);
            break;
        }''',
    '''        case 'N': {
            /* 展开通知栏：uinput 的 KEY_NOTIFICATION_CENTER 在三星上不生效，
             * cmd statusbar 同域注入失败，所以改成"从顶部边缘下滑"的真实触摸手势
             * （和用户手指下拉通知栏完全一样）。 */
            int nw = g_disp_w > 0 ? g_disp_w : 2560;
            int nh = g_disp_h > 0 ? g_disp_h : 1600;
            pid_t nch = fork();
            if (nch == 0) {
                char ncmd[192];
                snprintf(ncmd, sizeof(ncmd),
                         "/system/bin/input -d 0 swipe %d 4 %d %d 320",
                         nw / 2, nw / 2, nh * 55 / 100);
                int rc = system(ncmd);
                out("NOTIF swipe rc=%d", rc);
                _exit(0);
            }
            out("NOTIF swipe async");
            break;
        }''', "notif-swipe")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
