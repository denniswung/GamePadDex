import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
start = s.index("static void caption_fullscreen_click(int displayId) {")
end = s.index("\n}\n", start) + 3
new_fn = r'''static void caption_fullscreen_click(int displayId) {
    // 1) which window has the focus (its package identifies the right block)
    char pkg[128] = {0};
    FILE *p = popen("dumpsys window windows 2>/dev/null | grep -m1 mCurrentFocus", "r");
    if (p) {
        char line[512];
        if (fgets(line, sizeof(line), p)) {
            char *u = strstr(line, " u0 ");
            if (!u) u = strstr(line, " u");
            if (u) {
                char *slash = strchr(u, '/');
                if (slash) {
                    size_t n = (size_t)(slash - u);
                    if (n > 4 && n < sizeof(pkg)) {
                        /* skip " u0 " */
                        char *nm = u + 1;
                        while (*nm == 'u' || (*nm >= '0' && *nm <= '9') || *nm == ' ') nm++;
                        size_t len = (size_t)(slash - nm);
                        if (len < sizeof(pkg)) { memcpy(pkg, nm, len); pkg[len] = 0; }
                    }
                }
            }
        }
        pclose(p);
    }
    out("CAPTION focus=%s", pkg[0] ? pkg : "?");

    // 2) its window frame -> caption button position
    int right = -1, top = -1;
    p = popen("dumpsys window windows 2>/dev/null", "r");
    if (!p) { out("CAPTION no-dumpsys"); return; }
    char line[512];
    int in_win = 0;
    while (fgets(line, sizeof(line), p)) {
        if (strstr(line, "Window{")) in_win = (pkg[0] && strstr(line, pkg)) ? 1 : 0;
        if (in_win) {
            char *f = strstr(line, "containing=[");
            int a, b, c2, d;
            if (f && sscanf(f, "containing=[%d,%d][%d,%d]", &a, &b, &c2, &d) == 4) {
                if (c2 > 0 && d > 0) { right = c2; top = b; break; }
            }
        }
    }
    pclose(p);
    if (right <= 0) {
        /* fall back: first frame in the dump */
        p = popen("dumpsys window windows 2>/dev/null | grep -m1 containing=", "r");
        if (p) {
            char l2[512];
            if (fgets(l2, sizeof(l2), p)) {
                char *f = strstr(l2, "containing=[");
                int a, b, c2, d;
                if (f && sscanf(f, "containing=[%d,%d][%d,%d]", &a, &b, &c2, &d) == 4) {
                    right = c2; top = b;
                }
            }
            pclose(p);
        }
    }
    if (right <= 0) { out("CAPTION not-found"); return; }
    int x = right - 84;
    int y = top + 30;
    out("CAPTION click %d,%d (right=%d top=%d focus=%s)", x, y, right, top, pkg);
    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
}
'''
s = s[:start] + new_fn + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("caption click rewritten")