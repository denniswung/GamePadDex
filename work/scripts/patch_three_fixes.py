import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

s = io.open(H, encoding="utf-8").read()

# ---------- 1) 居中：有界步进夹角 + 单步到中心（不再用 -30000 超大位移）----------
start = s.index("/* 居中：")
end = s.index("static void cmd_wheel(", start)
new_center = '''/* 居中：先用"多个有界小步"把指针推到左上角（一个 -30000 的大位移会把指针甩出屏幕、
 * 之后连 hover 都没有），再按增益一步走到屏幕中心。
 * 用法：O <w> <h> <park> <rot> [gain] */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    double gain = g_center_gain > 0.2 ? g_center_gain : 2.16;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    /* 1) 有界步进到左上角：总量约 1.2 屏，分成 40 步，每步很小 */
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    /* 2) 从(0,0)一步到中心 */
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
    out("CENTER(steps+gain %.2f) rot=%d -> %d,%d", gain, rot, tx, ty);
}

'''
s = s[:start] + new_center + s[end:]

# ---------- 2) 电源键：优先 uinput KEY_POWER，其次 input ----------
old_power = '''        case 'p': {
            /* 模拟电源键：helper 以 root 运行，input 命令可以直接注入
             * KEYCODE_POWER(26)，屏幕亮灭都生效。 */
            system("input keyevent 26");
            out("POWER");
            break;
        }'''
new_power = '''        case 'p': {
            /* 模拟电源键：优先用我们自己虚拟键盘的 KEY_POWER（内核级，不依赖
             * SELinux/binder），失败再退回 `input keyevent 26`。 */
            int ok = 0;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, 116 /* KEY_POWER */, 1);
                ev_syn(g_kbd);
                usleep(40 * 1000);
                ev_emit(g_kbd, EV_KEY, 116, 0);
                ev_syn(g_kbd);
                ok = 1;
            }
            if (!ok) system("input keyevent 26");
            out("POWER uinput=%d", ok);
            break;
        }'''
if old_power not in s:
    print("MISS power"); sys.exit(1)
s = s.replace(old_power, new_power, 1)

# ---------- 3) 杀前台：多来源取包名 + am force-stop + 直接杀进程 ----------
old_kill_start = s.index("        case 'f': {")
old_kill_end = s.index("        case '?':", old_kill_start)
new_kill = '''        case 'f': {
            /* 杀前台：包名依次尝试 dumpsys activity / dumpsys window / 缓存，
             * 然后 am force-stop（functional）+ 直接 SIGKILL 所有进程（兜底） */
            char pkg[192] = {0};
            const char *pipes[2] = {
                "/system/bin/dumpsys activity activities 2>/dev/null | /system/bin/grep -m1 topResumedActivity | /system/bin/sed 's/.*u0 \\\\([^ ]*\\\\)\\\\/.*/\\\\1/'",
                "/system/bin/dumpsys window 2>/dev/null | /system/bin/grep -m1 mCurrentFocus | /system/bin/sed 's/.*u0 \\\\([^ /]*\\\\)\\\\/.*/\\\\1/'"
            };
            for (int i = 0; i < 2 && !pkg[0]; i++) {
                FILE *fp = popen(pipes[i], "r");
                if (!fp) continue;
                if (fgets(pkg, sizeof(pkg), fp)) {
                    char *nl = strchr(pkg, '\\n');
                    if (nl) *nl = 0;
                }
                pclose(fp);
                if (pkg[0] == '\\0') pkg[0] = 0;
            }
            if (!pkg[0] && g_top_pkg[0]) {
                snprintf(pkg, sizeof(pkg), "%s", g_top_pkg);
            }
            if (pkg[0]) {
                char cmd[360];
                snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop %s >/dev/null 2>&1", pkg);
                int rc = system(cmd);
                int n = kill_pkg_procs(pkg);
                out("FORCE_STOP %s rc=%d killed=%d", pkg, rc, n);
            } else {
                out("FORCE_STOP none (no foreground package detected)");
            }
            break;
        }
'''
s = s[:old_kill_start] + new_kill + s[old_kill_end:]

# 缓存 top 包名（供 f 使用）
if "g_top_pkg" not in s:
    s = s.replace("static double g_center_gain = 2.16;",
                  "static double g_center_gain = 2.16;\n/* 最近一次成功解析到的前台包名（杀应用时用） */\nstatic char g_top_pkg[192];", 1)
    # top_package() 里记录
    s = s.replace('out("TOP %s", pkg);', 'snprintf(g_top_pkg, sizeof(g_top_pkg), "%s", pkg);\n            out("TOP %s", pkg);', 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper ok")
