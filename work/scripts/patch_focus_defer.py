import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# track input activity so the dump never runs in the middle of a gesture
rep("static int g_anchor_pending = 0;",
    "static int g_anchor_pending = 0;\n"
    "/* the accessibility dump briefly pauses the foreground app, so it is deferred\n"
    " * until the input has been quiet for a moment */\n"
    "static int g_focus_want = 0;\n"
    "static long long g_last_input_ms = 0;", "fields")

# mark activity on every key/axis event read
rep('        out("KEY %d %d %d %lld", g_devs[i].id, ev->code, ev->value, now_ms());',
    '        out("KEY %d %d %d %lld", g_devs[i].id, ev->code, ev->value, now_ms());\n'
    '        g_last_input_ms = now_ms();', "key activity")

rep('out("AX %d %d %.4f", g_devs[i].id, axis_to_android(&g_devs[i], ev->code),',
    'out("AX %d %d %.4f", g_devs[i].id, axis_to_android(&g_devs[i], ev->code),', "noop")

# focus_refresh: remember the request instead of dumping right away
rep("""static void focus_refresh(void) {
    if (g_focus_child > 0) {
        int st = 0;
        if (waitpid(g_focus_child, &st, WNOHANG) == 0) return;   /* still running */
        g_focus_child = 0;
    }
    if (focus_valid()) return;""",
"""static void focus_refresh(void) {
    if (focus_valid()) return;
    /* the actual dump happens in the poll loop once the input is quiet */
    g_focus_want = 1;
}

/* called from the poll loop: start the dump when nothing is being pressed */
static void focus_maybe_dump(void) {
    if (!g_focus_want) return;
    if (now_ms() - g_last_input_ms < 700) return;
    g_focus_want = 0;
    if (g_focus_child > 0) {
        int st = 0;
        if (waitpid(g_focus_child, &st, WNOHANG) == 0) return;   /* still running */
        g_focus_child = 0;
    }
    if (focus_valid()) return;""", "defer refresh")

rep("static void focus_shell_ensure(void) {", "static void focus_shell_ensure(void) {", "noop2")

# call it from the poll loop
rep("""        int n = 0;
        pfd[n].fd = STDIN_FILENO; pfd[n].events = POLLIN; n++;""",
"""        focus_maybe_dump();
        int n = 0;
        pfd[n].fd = STDIN_FILENO; pfd[n].events = POLLIN; n++;""", "loop hook")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("done")
