import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old = '''    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
    /* diagnostics only: never block the command loop with a ~2 s dump */
    out("INFO uia %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);
    out("INFO worker %d", ({ FILE *wf = fopen(FOCUS_PID, "r"); int ok = 0;
        if (wf) { int p = 0; ok = (fscanf(wf, "%d", &p) == 1) && pid_is_worker((pid_t)p); fclose(wf); }
        ok; }));
    out("CAP screen %d", readable);
    out("CAP devices %d", g_ndev);'''
new = '''    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
    /* diagnostics only: never block the command loop with a ~2 s dump */
    {
        int worker = 0;
        FILE *wf = fopen(FOCUS_PID, "r");
        if (wf) {
            int p = 0;
            worker = (fscanf(wf, "%d", &p) == 1) && pid_is_worker((pid_t)p);
            fclose(wf);
        }
        out("INFO worker %d", worker);
    }
    out("CAP screen %d", screen_awake_readable());
    out("CAP devices %d", g_ndev);'''
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)

# helper: a cheap "is mWakefulness readable" probe (no popen per selftest? it is cheap)
old2 = '''/* 链路自检 (通用 §8.1): one line per capability */'''
new2 = '''/* readable screen state? (cheap: one grep on dumpsys power) */
static int screen_awake_readable(void) {
    FILE *p = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -c mWakefulness=", "r");
    int ok = 0;
    if (p) {
        char b[32] = {0};
        if (fgets(b, sizeof(b), p)) ok = atoi(b) > 0 ? 1 : 0;
        pclose(p);
    }
    return ok;
}

/* 链路自检 (通用 §8.1): one line per capability */'''
s = s.replace(old2, new2, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
