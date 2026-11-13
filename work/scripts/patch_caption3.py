import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
start = s.index("static void caption_fullscreen_click(int displayId, int screen_w) {")
end = s.index("\n}\n", start) + 3
new_fn = r'''static void caption_fullscreen_click(int displayId, int screen_w) {
    /* The DeX caption is a SystemUI window and the app window always reports
       (0,0)(fillxfill), so the real window rect lives in the task bounds.
       Layout measured on this device inside the caption:
         windowed : fullscreen icon = right-88,  caption row = top+30
         maximized: fullscreen icon = width-115, y = 30 (an extra button appears) */
    int bx1 = -1, by1 = -1, bx2 = -1, by2 = -1;
    FILE *p = popen("dumpsys activity activities 2>/dev/null | grep 'bounds=\\['", "r");
    if (p) {
        char line[256];
        while (fgets(line, sizeof(line), p)) {
            int a, b, c, d;
            char *f = strstr(line, "bounds=[");
            if (!f) continue;
            if (sscanf(f, "bounds=[%d,%d][%d,%d]", &a, &b, &c, &d) != 4) continue;
            if (c - a < 200 || d - b < 200) continue;                 /* too small */
            if (screen_w > 0 && c > screen_w + 10) continue;
            if (a == 0 && b == 0 && screen_w > 0 && c >= screen_w - 10) continue;  /* full display */
            if (bx1 < 0 || (long)(c - a) * (d - b) < (long)(bx2 - bx1) * (by2 - by1)) {
                bx1 = a; by1 = b; bx2 = c; by2 = d;     /* smallest real window */
            }
        }
        pclose(p);
    }
    int x, y;
    if (bx1 >= 0) {
        x = bx2 - 88;
        y = by1 + 30;
        out("CAPTION window rect [%d,%d][%d,%d] -> click %d,%d", bx1, by1, bx2, by2, x, y);
    } else if (screen_w > 0) {
        x = screen_w - 115;
        y = 30;
        out("CAPTION maximized -> click %d,%d (w=%d)", x, y, screen_w);
    } else {
        out("CAPTION not-found");
        return;
    }
    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
}
'''
s = s[:start] + new_fn + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("caption click now uses task bounds")
