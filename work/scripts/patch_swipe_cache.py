import io, sys, re
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# ---------- 1) 任务边界缓存 + 后台刷新 + 指针位置缓存 ----------
rep("static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {",
    r'''/* ---------------------------------------------------------------- 滑动用的缓存
 * cmd_swipe 以前每次都同步 popen("dumpsys activity activities") 取前台 task 边界，
 * 一次 100~300 ms，滑动首帧会明显卡一下。现在改成：
 *   - 边界读缓存文件 /data/adb/gpm/taskbounds.txt（子进程后台刷新，最多 2 秒一次）
 *   - 光标位置由 App 随命令一起传过来（App 自己知道估算位置），不再 dumpsys input
 * 这样滑动命令本身就是纯内存计算 + fork 注入，主循环零阻塞。 */
#define BOUNDS_CACHE "/data/adb/gpm/taskbounds.txt"

/* 最近一次已知的光标位置（App 传进来的），用于没有显式传坐标时的回退 */
static int g_ptr_x = -1, g_ptr_y = -1;

static int bounds_cache_read(int *x1, int *y1, int *x2, int *y2) {
    FILE *f = fopen(BOUNDS_CACHE, "r");
    if (!f) return 0;
    int a = 0, b = 0, c = 0, d = 0;
    int ok = fscanf(f, "%d %d %d %d", &a, &b, &c, &d) == 4;
    fclose(f);
    if (!ok || c <= a || d <= b) return 0;
    *x1 = a; *y1 = b; *x2 = c; *y2 = d;
    return 1;
}

static void bounds_cache_refresh_async(int maxX, int maxY) {
    struct stat st;
    if (stat(BOUNDS_CACHE, &st) == 0 && time(NULL) - st.st_mtime < 2) return;
    pid_t c = fork();
    if (c != 0) return;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY, found = 0;
    if (t) {
        char tl[2048];
        int l0 = 0, t0 = 0, r0 = 0, b0 = 0, have = 0, since = 999;
        while (fgets(tl, sizeof(tl), t)) {
            since++;
            char *mb = strstr(tl, "mBounds=Rect(");
            if (mb) {
                int x1 = 0, y1 = 0, x2 = 0, y2 = 0;
                if (sscanf(mb + strlen("mBounds=Rect("), "%d, %d - %d, %d", &x1, &y1, &x2, &y2) == 4) {
                    l0 = x1; t0 = y1; r0 = x2; b0 = y2;
                    have = 1; since = 0;
                }
            }
            if (strstr(tl, "topResumedActivity=ActivityRecord{")) {
                if (have && since <= 12 && r0 > l0 && b0 > t0 &&
                    r0 <= maxX + 200 && b0 <= maxY + 200) {
                    bx1 = l0; by1 = t0; bx2 = r0; by2 = b0; found = 1;
                }
                break;
            }
        }
        pclose(t);
    }
    if (found) {
        FILE *f = fopen(BOUNDS_CACHE ".tmp", "w");
        if (f) {
            fprintf(f, "%d %d %d %d\n", bx1, by1, bx2, by2);
            fclose(f);
            rename(BOUNDS_CACHE ".tmp", BOUNDS_CACHE);
        }
    } else {
        /* 没解析出来也写个空标记，避免每帧都 fork 重试 */
        FILE *f = fopen(BOUNDS_CACHE ".tmp", "w");
        if (f) { fprintf(f, "0 0 %d %d\n", maxX, maxY); fclose(f); rename(BOUNDS_CACHE ".tmp", BOUNDS_CACHE); }
    }
    _exit(0);
}

static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {''', "cache-fns")

# ---------- 2) cmd_swipe 里换成缓存读取 ----------
rep('''    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");
    if (t) {
        char tl[2048];
        int l0 = 0, t0 = 0, r0 = 0, b0 = 0, have = 0, since = 999;
        while (fgets(tl, sizeof(tl), t)) {
            since++;
            char *mb = strstr(tl, "mBounds=Rect(");
            if (mb) {
                int x1 = 0, y1 = 0, x2 = 0, y2 = 0;
                if (sscanf(mb + strlen("mBounds=Rect("), "%d, %d - %d, %d", &x1, &y1, &x2, &y2) == 4) {
                    l0 = x1;
                    t0 = y1;
                    r0 = x2;
                    b0 = y2;
                    have = 1;
                    since = 0;
                }
            }
            if (strstr(tl, "topResumedActivity=ActivityRecord{")) {
                if (have && since <= 12 && r0 > l0 && b0 > t0 &&
                    r0 <= maxX + 200 && b0 <= maxY + 200) {
                    bx1 = l0;
                    by1 = t0;
                    bx2 = r0;
                    by2 = b0;
                }
                break;
            }
        }
        pclose(t);
    }
    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;
    /* prefer the mouse pointer when it is over the app */
    int cx = -1, cy = -1;
    read_pointer(&cx, &cy);
    if (cx > bx1 + 10 && cx < bx2 - 10 && cy > by1 + 10 && cy < by2 - 10) {
        x = cx;
        y = cy;
    }''',
    '''    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    if (!bounds_cache_read(&bx1, &by1, &bx2, &by2)) {
        bx1 = 0; by1 = 0; bx2 = maxX; by2 = maxY;
    }
    /* 后台刷新边界（2 秒节流），本次用缓存/全屏兜底，绝不同步 dumpsys */
    bounds_cache_refresh_async(maxX, maxY);

    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;
    /* 光标位置：优先用命令里带的坐标（App 传的），其次用上次已知值；
     * 都不行就落在 task 中心。不再调用 dumpsys input。 */
    int cx = -1, cy = -1;
    if (have_cursor) { cx = cursor_x; cy = cursor_y; g_ptr_x = cursor_x; g_ptr_y = cursor_y; }
    else if (g_ptr_x >= 0 && g_ptr_y >= 0) { cx = g_ptr_x; cy = g_ptr_y; }
    if (cx > bx1 + 10 && cx < bx2 - 10 && cy > by1 + 10 && cy < by2 - 10) {
        x = cx;
        y = cy;
    }''', "swipe-bounds")

# ---------- 3) cmd_swipe 签名加 cursor 参数 + 计时 ----------
rep("static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {",
    "static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct,\n                      int have_cursor, int cursor_x, int cursor_y) {", "sig")

# 计时：入口打点，出口打印 prep 时间
rep('''    if (delta == 0) return;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;''',
    '''    if (delta == 0) return;
    struct timespec t_start, t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;''', "prep-start")

rep('''    out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) async", display, x, y, x2, y2,
        bx1, bx2, by1, by2);''',
    '''    clock_gettime(CLOCK_MONOTONIC, &t_end);
    long long prep_us = (long long)(t_end.tv_sec - t_start.tv_sec) * 1000000 +
                        (t_end.tv_nsec - t_start.tv_nsec) / 1000;
    out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) async prep=%lldus", display, x, y, x2, y2,
        bx1, bx2, by1, by2, prep_us);''', "prep-log")

# ---------- 4) 命令解析：V/Z 支持可选光标坐标 ----------
rep('''        case 'V': {
            int disp, dx, ms, mx, my;
            int pct = -1;
            int n = sscanf(line, "%d %d %d %d %d %d", &disp, &dx, &ms, &mx, &my, &pct);
            if (n >= 5) cmd_swipe(disp, dx, ms, mx, my, 0, pct);
            break;
        }''',
    '''        case 'V': {
            int disp, dx, ms, mx, my;
            int pct = -1, cx = -1, cy = -1;
            int n = sscanf(line, "%d %d %d %d %d %d %d %d", &disp, &dx, &ms, &mx, &my, &pct, &cx, &cy);
            if (n >= 5) cmd_swipe(disp, dx, ms, mx, my, 0, pct, n >= 8, cx, cy);
            break;
        }''', "case-V")
rep('''        case 'Z': {
            int disp, dy, ms, mx, my;
            int pct = -1;
            int n = sscanf(line, "%d %d %d %d %d %d", &disp, &dy, &ms, &mx, &my, &pct);
            if (n >= 5) cmd_swipe(disp, dy, ms, mx, my, 1, pct);
            break;
        }''',
    '''        case 'Z': {
            int disp, dy, ms, mx, my;
            int pct = -1, cx = -1, cy = -1;
            int n = sscanf(line, "%d %d %d %d %d %d %d %d", &disp, &dy, &ms, &mx, &my, &pct, &cx, &cy);
            if (n >= 5) cmd_swipe(disp, dy, ms, mx, my, 1, pct, n >= 8, cx, cy);
            break;
        }''', "case-Z")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
