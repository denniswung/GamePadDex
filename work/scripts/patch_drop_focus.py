import io, sys, re
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def cut(start_marker, end_marker, tag):
    global s
    a = s.index(start_marker)
    b = s.index(end_marker, a)
    s = s[:a] + s[b:]
    print("cut", tag)

# 1) drop the whole uiautomator focus block (worker, dump, refresh, anchor, cache)
cut("/* ---------------- control-level focus (通用 §4.4) ----------------",
    "/* readable screen state? (cheap: one grep on dumpsys power) */",
    "focus block")

# 2) selftest: no uiautomator / worker / focus rect lines
old = '''    out("CAP focus %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);
    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);'''
new = '''    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);'''
if old not in s:
    print("MISS selftest head"); sys.exit(1)
s = s.replace(old, new, 1)

# worker diagnostic + focus_rect line
a = s.index('    /* diagnostics only: never block the command loop with a ~2 s dump */')
b = s.index('    out("CAP screen %d", screen_awake_readable());', a)
s = s[:a] + s[b:]
print("cut worker diag")

a = s.index('    focus_load();\n    out("CAP focus_rect')
b = s.index('    out("SELFTEST end");', a)
s = s[:a] + s[b:]
print("cut focus_rect")

# 3) swipe: back to task bounds only
old = '''    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    /* 焦点优先: a fresh scrollable-control rectangle wins over the task bounds */
    focus_load();
    int focusUsed = 0;
    if (focus_valid()) {
        bx1 = g_fx1; by1 = g_fy1; bx2 = g_fx2; by2 = g_fy2;
        focusUsed = 1;
    }
    FILE *t = focusUsed ? NULL : popen("dumpsys activity activities 2>/dev/null", "r");'''
new = '''    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");'''
if old not in s:
    print("MISS swipe bounds"); sys.exit(1)
s = s.replace(old, new, 1)

s = s.replace('''        out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d age=%lld) rc=%d", display, x, y, x2, y2,
            focusUsed ? "focus" : "task", bx1, bx2, by1, by2,
            focusUsed ? now_ms() - g_focus_at : -1LL, rc);''',
'''        out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) rc=%d", display, x, y, x2, y2,
            bx1, bx2, by1, by2, rc);''', 1)
s = s.replace('''    out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d age=%lld) async", display, x, y, x2, y2,
        focusUsed ? "focus" : "task", bx1, bx2, by1, by2,
        focusUsed ? now_ms() - g_focus_at : -1LL);''',
'''    out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) async", display, x, y, x2, y2,
        bx1, bx2, by1, by2);''', 1)
print("ok swipe logs")

# 4) commands q / c / n
old = '''        case 'q':
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
        case 'c': {
            int on = 1;
            sscanf(line, "%d", &on);
            g_focus_enabled = on ? 1 : 0;
            out("FOCUS_ENABLED %d", g_focus_enabled);
            break;
        }
'''
# remove the 'g', 'q', 'n', 'c' handlers in whatever order they appear
for tag, pat in [
    ("q", "        case 'q':\n            focus_refresh();\n            break;\n"),
    ("n", "        case 'n':\n            focus_anchor();\n            break;\n"),
    ("g", '''        case 'g':
            focus_load();
            if (focus_valid()) {
                out("FOCUS %d %d %d %d age=%lld", g_fx1, g_fy1, g_fx2, g_fy2, now_ms() - g_focus_at);
            } else {
                out("FOCUS none");
            }
            break;
'''),
    ("c", '''        case 'c': {
            int on = 1;
            sscanf(line, "%d", &on);
            g_focus_enabled = on ? 1 : 0;
            out("FOCUS_ENABLED %d", g_focus_enabled);
            break;
        }
'''),
]:
    if pat in s:
        s = s.replace(pat, "", 1)
        print("cut cmd", tag)
    else:
        print("skip cmd", tag)

# 5) poll loop hook
s = s.replace("        focus_maybe_dump();\n", "", 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("written")
