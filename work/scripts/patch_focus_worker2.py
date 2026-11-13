import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("static const char *FOCUS_SHELL_SRC =")
end = s.index("static int focus_dump(void) {")
new = r'''static const char *FOCUS_SHELL_SRC =
    "#!/system/bin/sh\n"
    "while :; do\n"
    "  if [ -e " FOCUS_REQ " ]; then\n"
    "    rm -f " FOCUS_REQ "\n"
    "    /system/bin/uiautomator dump --compressed " FOCUS_UI
        " >/data/adb/gpm/worker.log 2>&1\n"
    "    touch " FOCUS_DONE "\n"
    "  fi\n"
    "  sleep 0.15\n"
    "done\n";

/* pid reuse makes a bare "does /proc/<pid> exist" check unreliable: also make
 * sure the process really is our worker */
static int pid_is_worker(pid_t pid) {
    if (pid <= 1) return 0;
    char p[40];
    snprintf(p, sizeof(p), "/proc/%d/cmdline", (int)pid);
    int fd = open(p, O_RDONLY);
    if (fd < 0) return 0;
    char buf[256] = {0};
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return 0;
    return strstr(buf, "focus_shell") != NULL;
}

static void focus_shell_ensure(void) {
    FILE *f = fopen(FOCUS_PID, "r");
    if (f) {
        int pid = 0;
        int ok = (fscanf(f, "%d", &pid) == 1) && pid_is_worker((pid_t)pid);
        fclose(f);
        if (ok) return;
    }
    FILE *w = fopen(FOCUS_SHELL, "w");
    if (!w) return;
    fputs(FOCUS_SHELL_SRC, w);
    fclose(w);
    chmod(FOCUS_SHELL, 0755);
    unlink(FOCUS_DONE);
    unlink(FOCUS_REQ);
    /* a single detached worker in the global mount namespace (ART APEX) */
    system("/system/bin/sh -c 'setsid /system/bin/su -M -c "
           "\"echo \\$\\$ > " FOCUS_PID "; exec /system/bin/sh " FOCUS_SHELL "\" "
           "</dev/null >/dev/null 2>&1 &'");
    for (int i = 0; i < 20; i++) {
        usleep(100 * 1000);
        FILE *r = fopen(FOCUS_PID, "r");
        if (r) {
            int pid = 0;
            int ok = (fscanf(r, "%d", &pid) == 1) && pid_is_worker((pid_t)pid);
            fclose(r);
            if (ok) return;
        }
    }
}

'''
s = s[:start] + new + s[end:]

# request: no pre-unlink of the dump (the worker overwrites it), check freshness
old_req = s[s.index("static int focus_dump(void) {"):]
old_req = old_req[:old_req.index("static void focus_refresh(void) {")]
new_req = r'''static int focus_dump(void) {
    focus_shell_ensure();
    unlink(FOCUS_DONE);
    FILE *t = fopen(FOCUS_REQ, "w");
    if (!t) return -1;
    fputc('1', t);
    fclose(t);
    /* a real dump takes ~2 s */
    for (int i = 0; i < 90; i++) {
        if (access(FOCUS_DONE, F_OK) == 0) break;
        usleep(100 * 1000);
    }
    unlink(FOCUS_DONE);
    if (file_size(FOCUS_UI) >= FOCUS_MIN_BYTES) return 0;
    out("FOCUS_DUMP failed (size=%ld)", file_size(FOCUS_UI));
    return -1;
}

'''
s = s.replace(old_req, new_req, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
