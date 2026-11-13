import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("/* The dump has to run detached")
end = s.index("static void focus_refresh(void) {")
new = r'''/*
 * The accessibility dump must run in the global mount namespace (the helper's
 * own namespace has no ART APEX, so app_process cannot link). Spawning
 * `su -M` for every dump only works once, so a single detached shell keeps
 * running there and is driven through two marker files.
 */
#define FOCUS_SHELL  "/data/adb/gpm/focus_shell.sh"
#define FOCUS_PID    "/data/adb/gpm/focus_shell.pid"
#define FOCUS_REQ    "/data/adb/gpm/focus_req"
#define FOCUS_DONE   "/data/adb/gpm/focus_done"

static const char *FOCUS_SHELL_SRC =
    "#!/system/bin/sh\n"
    "while :; do\n"
    "  if [ -e " FOCUS_REQ " ]; then\n"
    "    rm -f " FOCUS_REQ "\n"
    "    /system/bin/uiautomator dump --compressed " FOCUS_UI " >/dev/null 2>&1\n"
    "    touch " FOCUS_DONE "\n"
    "  fi\n"
    "  sleep 0.15\n"
    "done\n";

static int pid_alive(pid_t pid) {
    if (pid <= 1) return 0;
    char p[32];
    snprintf(p, sizeof(p), "/proc/%d", (int)pid);
    return access(p, F_OK) == 0;
}

static void focus_shell_ensure(void) {
    /* is the worker still there? */
    FILE *f = fopen(FOCUS_PID, "r");
    if (f) {
        int pid = 0;
        if (fscanf(f, "%d", &pid) == 1 && pid_alive(pid)) {
            fclose(f);
            return;
        }
        fclose(f);
    }
    FILE *w = fopen(FOCUS_SHELL, "w");
    if (!w) return;
    fputs(FOCUS_SHELL_SRC, w);
    fclose(w);
    chmod(FOCUS_SHELL, 0755);
    unlink(FOCUS_DONE);
    unlink(FOCUS_REQ);
    system("/system/bin/sh -c 'setsid /system/bin/su -M -c "
           "\"/system/bin/sh " FOCUS_SHELL "\" </dev/null >/dev/null 2>&1 &'");
    /* the worker writes its own pid */
    usleep(300 * 1000);
}

static int focus_dump(void) {
    focus_shell_ensure();
    unlink(FOCUS_DONE);
    unlink(FOCUS_UI);
    FILE *t = fopen(FOCUS_REQ, "w");
    if (!t) return -1;
    fputc('1', t);
    fclose(t);
    /* the worker takes ~2 s for a real dump */
    for (int i = 0; i < 80; i++) {
        if (access(FOCUS_DONE, F_OK) == 0) break;
        usleep(100 * 1000);
    }
    unlink(FOCUS_DONE);
    if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) return 0;
    out("FOCUS_DUMP failed (size=%ld)", file_size(FOCUS_UI));
    return -1;
}

'''
s = s[:start] + new + s[end:]

# the worker script needs to record its pid: start it through a wrapper
s = s.replace('''    system("/system/bin/sh -c 'setsid /system/bin/su -M -c "
           "\\"/system/bin/sh " FOCUS_SHELL "\\" </dev/null >/dev/null 2>&1 &'");''',
'''    system("/system/bin/sh -c 'setsid /system/bin/su -M -c \\"/system/bin/sh -c "
           "\\\\\\"echo \\\\\\$\\\\\\$ > " FOCUS_PID "; exec /system/bin/sh " FOCUS_SHELL "\\\\\\"\\" "
           "</dev/null >/dev/null 2>&1 &'");''')

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
