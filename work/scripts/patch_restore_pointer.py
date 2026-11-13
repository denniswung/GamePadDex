import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
# remember the pointer position before the click and restore it afterwards
old = """    int x, y;
    if (bx1 >= 0) {"""
assert old in s
new = """    int before_x = -1, before_y = -1;
    query_cursor_pos(&before_x, &before_y);   /* the absolute click moves the pointer */
    int x, y;
    if (bx1 >= 0) {"""
s = s.replace(old, new, 1)

old2 = """    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
}
"""
assert old2 in s
new2 = """    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
    /* put the pointer back where it was so the user keeps their cursor */
    if (before_x > 0 && before_y > 0) {
        usleep(180 * 1000);
        cmd_mouse_move((double)(before_x - x), (double)(before_y - y));
        out("CAPTION restored pointer to %d,%d", before_x, before_y);
    }
}
"""
s = s.replace(old2, new2, 1)

# a reusable cursor query (the old query_cursor prints; this one returns values)
if "query_cursor_pos" not in s.split("static void caption_fullscreen_click")[0]:
    fn = r'''
// same parse as query_cursor() but returns the numbers
static void query_cursor_pos(int *ox, int *oy) {
    *ox = -1; *oy = -1;
    FILE *p = popen("dumpsys SurfaceFlinger 2>/dev/null", "r");
    if (!p) return;
    char line[512];
    int seen = 0, rows = 0;
    double x = -1, y = -1;
    while (fgets(line, sizeof(line), p)) {
        if (!seen) {
            if (strstr(line, "LayerFE ([BBQ] Sprite")) seen = 1;
            continue;
        }
        double a, b, c;
        if (sscanf(line, " %lf %lf %lf", &a, &b, &c) == 3) {
            if (rows == 0) { x = c; rows = 1; }
            else { y = c; break; }
        }
    }
    pclose(p);
    if (x > 0 && y > 0) { *ox = (int)x; *oy = (int)y; }
}

'''
    s = s.replace("static void caption_fullscreen_click(int displayId, int screen_w) {",
                  fn + "static void caption_fullscreen_click(int displayId, int screen_w) {", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("pointer restore added")