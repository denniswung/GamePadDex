import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# ---------- 1. includes + monotonic clock ----------
rep("#include <errno.h>", "#include <errno.h>\n#include <time.h>\n#include <sys/wait.h>", "includes")

rep("static int g_ino_fd = -1;", """static int g_ino_fd = -1;

/* monotonic milliseconds: the app uses System.nanoTime()/1e6 (same clock), so
 * the stamps can be subtracted to get the real input latency */
static long long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000LL + ts.tv_nsec / 1000000LL;
}""", "now_ms")

# ---------- 2. latency stamps on AX/KEY ----------
rep('out("KEY %d %d %d", g_devs[i].id, ev->code, ev->value);',
    'out("KEY %d %d %d %lld", g_devs[i].id, ev->code, ev->value, now_ms());', "KEY stamp")

# ---------- 3. focus cache + selftest (before cmd_swipe) ----------
rep("static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {",
r'''/* ---------------- control-level focus (通用 §4.4) ----------------
 * The only general source of "is this control scrollable" is the
 * accessibility tree (uiautomator). One dump costs ~2 s, so it runs in a
 * forked child at most every FOCUS_TTL ms and only while the user is
 * actually scrolling; swipes keep using the last cached rectangle. */
#define FOCUS_FILE "/data/adb/gpm/focus.txt"
#define FOCUS_UI   "/data/local/tmp/gpm_focus_ui.xml"
#define FOCUS_TTL  5000

static int g_fx1 = -1, g_fy1 = -1, g_fx2 = -1, g_fy2 = -1;
static long long g_focus_at = 0;
static pid_t g_focus_child = 0;

static void focus_load(void) {
    FILE *f = fopen(FOCUS_FILE, "r");
    if (!f) return;
    int a = 0, b = 0, c = 0, d = 0;
    long long t = 0;
    if (fscanf(f, "%d %d %d %d %lld", &a, &b, &c, &d, &t) == 5 && c > a && d > b) {
        g_fx1 = a; g_fy1 = b; g_fx2 = c; g_fy2 = d; g_focus_at = t;
    }
    fclose(f);
}

static int focus_valid(void) {
    if (g_fx1 < 0 || g_fx2 <= g_fx1) return 0;
    return (now_ms() - g_focus_at) < FOCUS_TTL;
}

/* pick the smallest scrollable node that contains (px,py); fall back to the
 * largest one when the pointer is outside every list */
static int focus_parse(const char *path, int px, int py, int *x1, int *y1, int *x2, int *y2) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    if (n <= 0 || n > (2 << 20)) { fclose(f); return 0; }
    fseek(f, 0, SEEK_SET);
    char *buf = (char *)malloc(n + 1);
    if (!buf) { fclose(f); return 0; }
    size_t rd = fread(buf, 1, n, f);
    buf[rd] = 0;
    fclose(f);
    int bestA = 0, bestContains = 0;
    int bx1 = 0, by1 = 0, bx2 = 0, by2 = 0;
    char *p = buf;
    while ((p = strstr(p, "scrollable=\"true\"")) != NULL) {
        char *b = strstr(p, "bounds=\"[");
        if (!b) break;
        int a = 0, c = 0, d = 0, e = 0;
        if (sscanf(b + 8, "%d,%d][%d,%d", &a, &c, &d, &e) == 4 && d > a && e > c) {
            int area = (d - a) * (e - c);
            int contains = (px >= a && px <= d && py >= c && py <= e);
            if (contains && (!bestContains || area < bestA)) {
                bestContains = 1; bestA = area;
                bx1 = a; by1 = c; bx2 = d; by2 = e;
            } else if (!bestContains && area > bestA) {
                bestA = area;
                bx1 = a; by1 = c; bx2 = d; by2 = e;
            }
        }
        p = b;
    }
    free(buf);
    if (bx2 <= bx1 || by2 <= by1) return 0;
    *x1 = bx1; *y1 = by1; *x2 = bx2; *y2 = by2;
    return 1;
}

static void focus_write(int x1, int y1, int x2, int y2) {
    FILE *f = fopen(FOCUS_FILE ".tmp", "w");
    if (!f) return;
    fprintf(f, "%d %d %d %d %lld\n", x1, y1, x2, y2, now_ms());
    fclose(f);
    rename(FOCUS_FILE ".tmp", FOCUS_FILE);
}

/* async refresh: the parent keeps handling input while the child dumps */
static void focus_refresh(void) {
    if (g_focus_child > 0) {
        int st = 0;
        if (waitpid(g_focus_child, &st, WNOHANG) == 0) return;   /* still running */
        g_focus_child = 0;
    }
    if (focus_valid()) return;
    int px = -1, py = -1;
    read_pointer(&px, &py);
    pid_t pid = fork();
    if (pid != 0) {
        if (pid > 0) g_focus_child = pid;
        return;
    }
    system("/system/bin/uiautomator dump --compressed " FOCUS_UI " >/dev/null 2>&1");
    int x1 = 0, y1 = 0, x2 = 0, y2 = 0;
    if (focus_parse(FOCUS_UI, px, py, &x1, &y1, &x2, &y2)) {
        focus_write(x1, y1, x2, y2);
        out("FOCUS_SET %d,%d %d,%d (ptr %d,%d)", x1, y1, x2, y2, px, py);
    } else {
        out("FOCUS_NONE (ptr %d,%d)", px, py);
    }
    _exit(0);
}

/* anchor the pointer inside the focused list before a wheel scroll */
static void focus_anchor(void) {
    focus_load();
    if (!focus_valid()) return;
    int px = -1, py = -1;
    read_pointer(&px, &py);
    if (px >= g_fx1 + 8 && px <= g_fx2 - 8 && py >= g_fy1 + 8 && py <= g_fy2 - 8) return;
    int cx = (g_fx1 + g_fx2) / 2, cy = (g_fy1 + g_fy2) / 2;
    cmd_mouse_move(cx - px, cy - py);
    out("FOCUS_ANCHOR %d,%d -> %d,%d", px, py, cx, cy);
}

/* 链路自检 (通用 §8.1): one line per capability */
static void cmd_selftest(void) {
    out("SELFTEST begin");
    out("CAP mouse %d", g_mouse >= 0 ? 1 : 0);
    out("CAP kbd %d", g_kbd >= 0 ? 1 : 0);
    out("CAP wheel %d", (g_mouse >= 0) ? 1 : 0);
    out("CAP swipe %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP notif %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("CAP power %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP force %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("CAP focus %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);
    /* screen state readable? */
    FILE *p = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -c mWakefulness=", "r");
    int readable = 0;
    if (p) {
        char b[32] = {0};
        if (fgets(b, sizeof(b), p)) readable = atoi(b) > 0 ? 1 : 0;
        pclose(p);
    }
    out("CAP screen %d", readable);
    out("CAP devices %d", g_ndev);
    focus_load();
    out("CAP focus_rect %d,%d %d,%d age=%lld", g_fx1, g_fy1, g_fx2, g_fy2,
        g_focus_at ? (now_ms() - g_focus_at) : -1LL);
    out("SELFTEST end");
}

static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {''', "focus + selftest")

# ---------- 4. focus-aware swipe bounds ----------
rep("""    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");""",
"""    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    /* 焦点优先: a fresh scrollable-control rectangle wins over the task bounds */
    focus_load();
    int focusUsed = 0;
    if (focus_valid()) {
        int px = -1, py = -1;
        read_pointer(&px, &py);
        if (px >= g_fx1 - 4 && px <= g_fx2 + 4 && py >= g_fy1 - 4 && py <= g_fy2 + 4) {
            bx1 = g_fx1; by1 = g_fy1; bx2 = g_fx2; by2 = g_fy2;
            focusUsed = 1;
        }
    }
    FILE *t = focusUsed ? NULL : popen("dumpsys activity activities 2>/dev/null", "r");""", "swipe focus bounds")

rep("""    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;""",
"""    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;""", "noop")

# clamp the travel to the focus rect as well
rep("""        out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) rc=%d", display, x, y, x2, y2,
            bx1, bx2, by1, by2, rc);""",
"""        out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d) rc=%d", display, x, y, x2, y2,
            focusUsed ? "focus" : "task", bx1, bx2, by1, by2, rc);""", "swipe log rc")

rep("""    out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) async", display, x, y, x2, y2,
        bx1, bx2, by1, by2);""",
"""    out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d) async", display, x, y, x2, y2,
        focusUsed ? "focus" : "task", bx1, bx2, by1, by2);""", "swipe log async")

# ---------- 5. commands: q (refresh), g (get), n (anchor), ? (selftest) ----------
rep("""        case 'p': {""",
"""        case 'q':
            focus_refresh();
            break;
        case 'g':
            focus_load();
            if (focus_valid()) {
                out("FOCUS %d %d %d %d age=%lld", g_fx1, g_fy1, g_fx2, g_fy2, now_ms() - g_focus_at);
            } else {
                out("FOCUS none");
            }
            break;
        case 'n':
            focus_anchor();
            break;
        case '?':
            cmd_selftest();
            break;
        case 'p': {""", "new commands")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("written")
