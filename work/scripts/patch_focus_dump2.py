import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old = '''/* produce the accessibility dump; the KSU helper's environment sometimes
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
}'''
new = '''/* A real accessibility dump is 6–10 KB; anything smaller is a partial or stale
 * file. The KSU helper's own environment sometimes cannot link app_process, so
 * the dump is produced through `su -c` (a clean root shell) first. */
#define FOCUS_MIN_BYTES 2048

static long file_size(const char *p) {
    struct stat st;
    return (stat(p, &st) == 0) ? (long)st.st_size : -1;
}

static int focus_dump(void) {
    unlink(FOCUS_UI);
    int rc = system("/system/bin/su -c '/system/bin/uiautomator dump --compressed "
                    FOCUS_UI "' >/data/adb/gpm/uia.log 2>&1");
    if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) return 0;
    unlink(FOCUS_UI);
    rc = system("/system/bin/uiautomator dump --compressed " FOCUS_UI
                " >/data/adb/gpm/uia2.log 2>&1");
    if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) return 0;
    return rc != 0 ? rc : -1;
}'''
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
