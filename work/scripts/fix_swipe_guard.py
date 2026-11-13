import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# 1) 把保护区判断移到 y2 计算之后
old_guard = """    /* 手势保护区：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」，
     * 所以向下的滑动必须从保护区以下起手（这是桌面下滑拉出状态栏的根因）。 */
    if (vertical && delta > 0) {
        int guard = by1 + (by2 - by1) * 12 / 100;
        if (y < guard) y = guard;
        if (y2 < guard) y2 = guard;
    }"""
if old_guard not in s:
    print("MISS guard"); sys.exit(1)
s = s.replace(old_guard, "", 1)

old2 = """    if (ms <= 0) ms = 480;
    char cmd[256];"""
new2 = """    /* 手势保护区：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」，
     * 所以向下的滑动必须从保护区以下起手（这是桌面下滑拉出状态栏的根因）。 */
    if (vertical && delta > 0) {
        int guard = by1 + (by2 - by1) * 12 / 100;
        if (y < guard) { y = guard; y2 = guard + delta; }
        if (y2 > by2 - 20) y2 = by2 - 20;
    }
    if (ms <= 0) ms = 480;
    char cmd[256];"""
if old2 not in s:
    print("MISS tail"); sys.exit(1)
s = s.replace(old2, new2, 1)

# 2) case 'T' 已被占用 → 改用 't'
s = s.replace("        case 'T': {\n            /* 当前前台包名", "        case 't': {\n            /* 当前前台包名", 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)

R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
r = io.open(R, encoding="utf-8").read().replace('fun queryTop() = send("T")', 'fun queryTop() = send("t")')
io.open(R, "w", encoding="utf-8", newline="\n").write(r)
print("ok")
