import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("/* A real accessibility dump is 6–10 KB")
end = s.index("static void focus_refresh(void) {")
new = '''/* A real accessibility dump is 6–10 KB; anything smaller is a partial or stale
 * file. The KSU helper lives in a mount namespace without the ART APEX, so
 * app_process cannot link there; the dump is therefore produced in the global
 * mount namespace (`su -M`, then `nsenter`) and only then directly. */
#define FOCUS_MIN_BYTES 2048

static long file_size(const char *p) {
    struct stat st;
    return (stat(p, &st) == 0) ? (long)st.st_size : -1;
}

static int focus_dump(void) {
    static const char *cmds[] = {
        "/system/bin/su -M -c '/system/bin/uiautomator dump --compressed " FOCUS_UI "' "
            ">/data/adb/gpm/uia.log 2>&1",
        "/system/bin/nsenter -t 1 -m -- /system/bin/uiautomator dump --compressed "
            FOCUS_UI " >/data/adb/gpm/uia2.log 2>&1",
        "/system/bin/uiautomator dump --compressed " FOCUS_UI
            " >/data/adb/gpm/uia3.log 2>&1",
    };
    for (unsigned i = 0; i < sizeof(cmds) / sizeof(cmds[0]); i++) {
        unlink(FOCUS_UI);
        int rc = system(cmds[i]);
        if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) {
            if (i > 0) out("FOCUS_DUMP via #%u", i);
            return 0;
        }
        (void)rc;
    }
    return -1;
}

'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
