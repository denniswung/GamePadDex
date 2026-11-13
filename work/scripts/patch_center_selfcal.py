import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()

start = s.index("static void cmd_center(")
end = s.index("\n}\n", start) + 3
new = r'''/* Read the mouse hover position from `dumpsys input` (window-local pixels).
 * A delta between two reads is offset-free, which is enough to measure the
 * pointer gain; the offset itself is measured by parking in the corner. */
static int pointer_pos(float *px, float *py) {
    FILE *p = popen("dumpsys input 2>/dev/null", "r");
    if (!p) return 0;
    char line[1024];
    int found = 0;
    while (fgets(line, sizeof(line), p)) {
        if (!strstr(line, "hoveringPointers=[Pointer(id=0, MOUSE) at (")) continue;
        if (strstr(line, "[Gesture Monitor]")) continue;
        if (strstr(line, "StatusBar")) continue;
        if (strstr(line, "NavigationBar")) continue;
        const char *at = strstr(line, "at (");
        if (!at) continue;
        float x, y;
        if (sscanf(at + 4, "%f, %f", &x, &y) == 2) { *px = x; *py = y; found = 1; break; }
    }
    pclose(p);
    return found;
}

static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;

    /* park in the top-left corner: the window-local reading there is the
     * window origin, and the global position is local - origin */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(80 * 1000);
    float ox = 0, oy = 0, ax, ay, bx, by, cx, cy;
    int have_origin = pointer_pos(&ox, &oy);
    float gx = 0, gy = 0;
    if (have_origin) {
        cmd_mouse_move(200.0, 0.0);
        usleep(70 * 1000);
        if (pointer_pos(&ax, &ay) && fabsf(ax - ox) > 40) gx = (ax - ox) / 200.0f;
        cmd_mouse_move(0.0, 200.0);
        usleep(70 * 1000);
        if (pointer_pos(&bx, &by) && fabsf(by - oy) > 40) gy = (by - oy) / 200.0f;
        cmd_mouse_move(-30000.0, -30000.0);
        usleep(80 * 1000);
    }
    if (gx <= 0.05f) gx = 3.25f;   /* fallback: probe-measured default */
    if (gy <= 0.05f) gy = 3.25f;

    cmd_mouse_move(tx / gx, ty / gy);
    usleep(150 * 1000);

    float ex, ey;
    if (have_origin && pointer_pos(&ex, &ey)) {
        float curx = ex - ox, cury = ey - oy;   /* global position */
        float dx = tx - curx, dy = ty - cury;
        if (fabsf(dx) > 6 || fabsf(dy) > 6) {
            cmd_mouse_move(dx / gx, dy / gy);
            usleep(120 * 1000);
            if (pointer_pos(&ex, &ey)) { curx = ex - ox; cury = ey - oy; }
        }
        out("CENTER(gain %.2f,%.2f) -> target %d,%d at %.0f,%.0f", gx, gy, tx, ty, curx, cury);
    } else {
        out("CENTER(gain %.2f,%.2f) -> target %d,%d", gx, gy, tx, ty);
    }
}
'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("center rewritten")
