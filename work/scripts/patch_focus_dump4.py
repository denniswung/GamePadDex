import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old_start = s.index("static int focus_dump(void) {")
old_end = s.index("static void focus_refresh(void) {")
new = '''/* The dump has to run detached from the helper's socket stdio and in the global
 * mount namespace: `setsid` gives it its own session, `su -M`/`nsenter` put it
 * into the namespace where the ART APEX (and therefore app_process) exists. */
static const char *FOCUS_DUMP_CMDS[] = {
    "setsid /system/bin/su -M -c '/system/bin/uiautomator dump --compressed " FOCUS_UI "' "
        "</dev/null >/dev/null 2>&1",
    "setsid /system/bin/nsenter -t 1 -m -- /system/bin/uiautomator dump --compressed "
        FOCUS_UI " </dev/null >/dev/null 2>&1",
    "setsid /system/bin/sh -c '/system/bin/su -M -c \\"/system/bin/uiautomator dump "
        "--compressed " FOCUS_UI "\\"' </dev/null >/dev/null 2>&1",
};

static int focus_dump(void) {
    for (unsigned i = 0; i < sizeof(FOCUS_DUMP_CMDS) / sizeof(FOCUS_DUMP_CMDS[0]); i++) {
        unlink(FOCUS_UI);
        system(FOCUS_DUMP_CMDS[i]);
        if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) {
            if (i > 0) out("FOCUS_DUMP via #%u", i);
            return 0;
        }
    }
    out("FOCUS_DUMP failed");
    return -1;
}

'''
s = s[:old_start] + new + s[old_end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
