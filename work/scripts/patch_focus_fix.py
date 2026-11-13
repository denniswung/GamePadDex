import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# bounds="[" is 9 chars
rep('if (sscanf(b + 8, "%d,%d][%d,%d", &a, &c, &d, &e) == 4 && d > a && e > c) {',
    'if (sscanf(b + 9, "%d,%d][%d,%d", &a, &c, &d, &e) == 4 && d > a && e > c) {', "parse offset")

# the resolved focus rect already is "the container under the cursor, else the
# window's default scroll container", so the swipe can use it directly
rep("""    focus_load();
    int focusUsed = 0;
    if (focus_valid()) {
        int px = -1, py = -1;
        read_pointer(&px, &py);
        if (px >= g_fx1 - 4 && px <= g_fx2 + 4 && py >= g_fy1 - 4 && py <= g_fy2 + 4) {
            bx1 = g_fx1; by1 = g_fy1; bx2 = g_fx2; by2 = g_fy2;
            focusUsed = 1;
        }
    }""",
"""    focus_load();
    int focusUsed = 0;
    if (focus_valid()) {
        bx1 = g_fx1; by1 = g_fy1; bx2 = g_fx2; by2 = g_fy2;
        focusUsed = 1;
    }""", "swipe use focus")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("done")
