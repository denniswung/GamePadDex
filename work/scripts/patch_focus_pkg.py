import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

rep("static long long g_last_dump_req_ms = 0;",
    """static long long g_last_dump_req_ms = 0;
/* the rectangle only changes when the foreground app changes, so the dump runs
 * on app switches instead of every few seconds (uiautomator crashes when two
 * runs overlap: "UiAutomationService ... already registered") */
static char g_focus_pkg[128] = "";
static char g_top_pkg[128] = "";
static long long g_top_check_ms = 0;""", "pkg fields")

# helper: read the foreground package cheaply
rep("static void focus_maybe_dump(void) {",
'''/* foreground package (cheap: one grep over the activity dump) */
static void read_top_pkg(char *out, size_t n) {
    out[0] = 0;
    FILE *p = popen("/system/bin/dumpsys activity activities 2>/dev/null | "
                    "/system/bin/grep -m1 topResumedActivity", "r");
    if (!p) return;
    char line[512];
    if (fgets(line, sizeof(line), p)) {
        char *u = strstr(line, "u0 ");
        if (u) {
            u += 3;
            size_t i = 0;
            while (u[i] && u[i] != '/' && u[i] != ' ' && i + 1 < n) {
                out[i] = u[i];
                i++;
            }
            out[i] = 0;
        }
    }
    pclose(p);
}

static void focus_maybe_dump(void) {''', "read_top_pkg")

# only refresh on app switch
rep("""static void focus_maybe_dump(void) {
    if (!g_focus_want) return;""",
"""static void focus_maybe_dump(void) {
    long long now = now_ms();
    if (now - g_top_check_ms > 2000) {
        g_top_check_ms = now;
        read_top_pkg(g_top_pkg, sizeof(g_top_pkg));
        if (g_top_pkg[0] && strcmp(g_top_pkg, g_focus_pkg) != 0) g_focus_want = 1;
    }
    if (!g_focus_want) return;""", "switch detect")

# remember which package the rectangle belongs to
rep("""    if (focus_valid()) return;
    if (g_focus_child > 0) {""",
"""    if (focus_valid() && g_top_pkg[0] && strcmp(g_top_pkg, g_focus_pkg) == 0) return;
    if (g_focus_child > 0) {""", "valid check")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("done")
