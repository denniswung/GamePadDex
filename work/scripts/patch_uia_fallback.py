import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# a single place that produces the accessibility dump; `su -c` is the fallback
# because the KSU helper's own environment occasionally cannot link app_process
rep('''static void focus_refresh(void) {''',
'''/* produce the accessibility dump; the KSU helper's environment sometimes
 * cannot link app_process, so retry through `su -c` (a clean root shell) */
static int focus_dump(void) {
    struct stat st;
    int rc = system("/system/bin/uiautomator dump --compressed " FOCUS_UI
                    " >/data/adb/gpm/uia.log 2>&1");
    if (stat(FOCUS_UI, &st) != 0 || st.st_size < 512) {
        rc = system("/system/bin/su -c '/system/bin/uiautomator dump --compressed "
                    FOCUS_UI "' >/data/adb/gpm/uia2.log 2>&1");
        if (stat(FOCUS_UI, &st) == 0 && st.st_size >= 512) rc = 0;
    }
    return rc;
}

static void focus_refresh(void) {''', "focus_dump")

rep('''    system("/system/bin/uiautomator dump --compressed " FOCUS_UI " >/data/adb/gpm/uia.log 2>&1");
    int x1 = 0, y1 = 0, x2 = 0, y2 = 0;''',
'''    focus_dump();
    int x1 = 0, y1 = 0, x2 = 0, y2 = 0;''', "use focus_dump")

# selftest diagnostic uses the same path
rep('''    {
        int rc = system("/system/bin/uiautomator dump --compressed /data/local/tmp/gpm_st.xml "
                        ">/data/adb/gpm/uia_selftest.log 2>&1");
        FILE *lf = fopen("/data/adb/gpm/uia_selftest.log", "r");
        char l1[160] = {0};
        if (lf) { if (!fgets(l1, sizeof(l1), lf)) l1[0] = 0; fclose(lf); }
        char *nl = strchr(l1, '\\n');
        if (nl) *nl = 0;
        out("CAP uia rc=%d %s", rc, l1);
    }''',
'''    {
        int rc = focus_dump();
        struct stat st;
        long sz = (stat(FOCUS_UI, &st) == 0) ? (long)st.st_size : 0;
        out("CAP uia rc=%d bytes=%ld", rc, sz);
    }''', "selftest diag")

# focus_dump needs sys/stat.h
if "#include <sys/stat.h>" not in s:
    rep("#include <sys/wait.h>", "#include <sys/wait.h>\n#include <sys/stat.h>", "stat include")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("done")
