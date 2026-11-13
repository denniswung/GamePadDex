import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()

# 1) stop spawning app_process: it cannot link outside the shell domain and the
#    retry loop floods logcat every 2s (which also disturbs other app_process users)
old = "static void spawn_injector(void) {\n    if (g_inject_fd >= 0) return;   // already running"
assert old in c, "spawn guard not found"
c = c.replace(old, "static void spawn_injector(void) {\n    /* disabled: app_process cannot be used from this domain, so the injector is\n       not started at all; clicks use `input tap`, scrolling uses uinput */\n    if (1) return;\n    if (g_inject_fd >= 0) return;   // already running", 1)

# 2) the caption click goes through /system/bin/input (works without app_process)
old2 = """    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
    if (before_x > 0 && before_y > 0) {"""
assert old2 in c, "click block not found"
new2 = """    {
        char tap[128];
        snprintf(tap, sizeof(tap), "/system/bin/input -d %d tap %d %d >/dev/null 2>&1", displayId, x, y);
        system(tap);
        out("CAPTION tapped %d,%d", x, y);
    }
    if (before_x > 0 && before_y > 0) {"""
c = c.replace(old2, new2, 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("injector disabled, caption click uses input tap")