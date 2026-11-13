import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
start = s.index("static void caption_fullscreen_click(int displayId, int screen_w) {")
end = s.index("\n}\n", start) + 3
new_fn = r'''static void caption_fullscreen_click(int displayId, int screen_w, int screen_h) {
    /* 1) root: force the foreground task to fill the display (maximized) */
    char tid[16] = {0};
    FILE *p = popen("dumpsys activity activities 2>/dev/null | grep -m1 -oE 'Task\\{[^}]*#[0-9]+ type=standard A=[0-9]+:com\\.example\\.' 2>/dev/null", "r");
    if (!p) p = popen("dumpsys activity activities 2>/dev/null | grep -m1 -oE 'Task\\{[^}]*#[0-9]+' ", "r");
    if (p) {
        char line[512];
        if (fgets(line, sizeof(line), p)) {
            char *h = strrchr(line, '#');
            if (h) {
                int i = 0;
                h++;
                while (*h >= '0' && *h <= '9' && i < 8) tid[i++] = *h++;
                tid[i] = 0;
            }
        }
        pclose(p);
    }
    if (tid[0] && screen_w > 0 && screen_h > 0) {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "/system/bin/am task resize %s 0 0 %d %d >/dev/null 2>&1", tid, screen_w, screen_h);
        int rc = system(cmd);
        out("FULLSCREEN resize task %s -> %dx%d rc=%d", tid, screen_w, screen_h, rc);
        usleep(600 * 1000);
    }

    /* 2) the caption is now at the top-right of the display: click the
          fullscreen icon, then put the pointer back where it was */
    int before_x = -1, before_y = -1;
    query_cursor_pos(&before_x, &before_y);
    int x = screen_w > 0 ? screen_w - 115 : 2445;
    int y = 30;
    out("CAPTION click %d,%d", x, y);
    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
    if (before_x > 0 && before_y > 0) {
        usleep(200 * 1000);
        cmd_mouse_move((double)(before_x - x), (double)(before_y - y));
        out("CAPTION restored pointer to %d,%d", before_x, before_y);
    }
}
'''
s = s[:start] + new_fn + s[end:]
s = s.replace("""        case 'J': {
            int jd = 0, jw = 0;
            int n = sscanf(line, "%d %d", &jd, &jw);
            if (n >= 1 && jd > 0) caption_fullscreen_click(jd, n >= 2 ? jw : 0);
            break;
        }""",
"""        case 'J': {
            int jd = 0, jw = 0, jh = 0;
            int n = sscanf(line, "%d %d %d", &jd, &jw, &jh);
            if (n >= 1 && jd > 0) caption_fullscreen_click(jd, n >= 2 ? jw : 0, n >= 3 ? jh : 0);
            break;
        }""", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("resize+click fullscreen implemented")