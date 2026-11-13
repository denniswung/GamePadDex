import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
old = "static void caption_fullscreen_click(int displayId, int screen_w) {"
assert old in s
new = '''static void caption_fullscreen_click(int displayId, int screen_w) {
    /* DeX draws the caption in a SystemUI window (invisible to accessibility and
       to dumpsys window frames), but a maximized app fills the display, so the
       caption icons sit at a fixed offset from the display's top-right corner.
       Measured on this device: fullscreen icon = width-115, y = 30. */
    if (screen_w > 0) {
        int x = screen_w - 115;
        int y = 30;
        out("CAPTION direct click %d,%d (w=%d)", x, y, screen_w);
        if (g_inject_fd >= 0) {
            char buf[64];
            int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\\n", displayId, x, y);
            if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
        }
        return;
    }'''
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("direct click added")