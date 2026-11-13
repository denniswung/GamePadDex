import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old_start = s.index("static int focus_dump(void) {")
old_end = s.index("static void focus_refresh(void) {")
new = '''/* only one dump at a time: a second concurrent uiautomator run fails */
static volatile int g_dump_busy = 0;

static int focus_dump(void) {
    if (g_dump_busy) return -1;
    g_dump_busy = 1;
    int ok = -1;
    for (int round = 0; round < 2 && ok != 0; round++) {
        for (unsigned i = 0; i < sizeof(FOCUS_DUMP_CMDS) / sizeof(FOCUS_DUMP_CMDS[0]); i++) {
            unlink(FOCUS_UI);
            system(FOCUS_DUMP_CMDS[i]);
            if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) {
                if (i > 0 || round > 0) out("FOCUS_DUMP via #%u/#%d", i, round);
                ok = 0;
                break;
            }
        }
        if (ok != 0) usleep(500 * 1000);
    }
    if (ok != 0) out("FOCUS_DUMP failed");
    g_dump_busy = 0;
    return ok;
}

'''
s = s[:old_start] + new + s[old_end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
