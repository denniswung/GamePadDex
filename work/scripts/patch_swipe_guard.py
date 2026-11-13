import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
S = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineState.kt"

s = io.open(H, encoding="utf-8").read()

# 1) 顶栏保护区：向下滑不得从状态栏区域起手
old = """    if (x < bx1 + 20) x = bx1 + 20;
    if (x > bx2 - 20) x = bx2 - 20;
    if (y < by1 + 20) y = by1 + 20;
    if (y > by2 - 20) y = by2 - 20;"""
new = """    if (x < bx1 + 20) x = bx1 + 20;
    if (x > bx2 - 20) x = bx2 - 20;
    if (y < by1 + 20) y = by1 + 20;
    if (y > by2 - 20) y = by2 - 20;
    /* 手势保护区：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」，
     * 所以向下的滑动必须从保护区以下起手（这是桌面下滑拉出状态栏的根因）。 */
    if (vertical && delta > 0) {
        int guard = by1 + (by2 - by1) * 12 / 100;
        if (y < guard) y = guard;
        if (y2 < guard) y2 = guard;
    }"""
if old not in s:
    print("MISS guard"); sys.exit(1)
s = s.replace(old, new, 1)

# 2) 前台包名查询命令 T
anchor = "        case 'A': {"
if anchor not in s:
    print("MISS A"); sys.exit(1)
shortcut = '''        case 'T': {
            /* 当前前台包名：桌面/游戏要用 d-pad 转发，而不是触摸滑动 */
            char pkg[160];
            top_package(pkg, sizeof(pkg));
            out("TOP %s", pkg);
            break;
        }
'''
helper_fn = '''/* 读取当前前台包名（topResumedActivity） */
static void top_package(char *out_pkg, size_t n) {
    out_pkg[0] = 0;
    FILE *p = popen("/system/bin/dumpsys activity activities 2>/dev/null | "
                    "/system/bin/grep -m1 topResumedActivity", "r");
    if (!p) return;
    char line[512];
    if (fgets(line, sizeof(line), p)) {
        char *u = strstr(line, "u0 ");
        if (u) {
            u += 3;
            size_t i = 0;
            while (u[i] && u[i] != '/' && u[i] != ' ' && i + 1 < n) {
                out_pkg[i] = u[i];
                i++;
            }
            out_pkg[i] = 0;
        }
    }
    pclose(p);
}

'''
if "static void top_package" not in s:
    marker = "static void cmd_swipe("
    s = s.replace(marker, helper_fn + marker, 1)
s = s.replace(anchor, shortcut + anchor, 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper ok")

# 3) App: 查询前台包 + 桌面改用 d-pad 转发
r = io.open(R, encoding="utf-8").read()
if "fun queryTop()" not in r:
    r = r.replace('    fun hat(dir: Int, hold: Boolean = false)',
                  '    /** 查询当前前台包名（助手回 TOP <pkg>） */\n    fun queryTop() = send("T")\n\n    fun hat(dir: Int, hold: Boolean = false)', 1)
    # 解析 TOP
    r = r.replace('            line.startsWith("GONE ") -> {',
                  '            line.startsWith("TOP ") -> EngineState.topPackage = line.removePrefix("TOP ").trim()\n            line.startsWith("GONE ") -> {', 1)
    io.open(R, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

st = io.open(S, encoding="utf-8").read()
if "var topPackage" not in st:
    st = st.replace("    @Volatile var connected = false",
                    "    @Volatile var connected = false\n\n    /** 前台包名（助手 T 命令回填，用于判断是否桌面） */\n    @Volatile var topPackage = \"\"", 1)
    io.open(S, "w", encoding="utf-8", newline="\n").write(st)
    print("state ok")

e = io.open(E, encoding="utf-8").read()
# 周期查询前台包
if "root.queryTop()" not in e:
    e = e.replace("""        // d-pad 统一走 App（软件在虚拟控制器层之上），助手不再自己转发，""",
"""        if (ticks % 120 == 0L) root.queryTop()
        // d-pad 统一走 App（软件在虚拟控制器层之上），助手不再自己转发，""", 1)
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
    print("engine poll ok")
print("done")
