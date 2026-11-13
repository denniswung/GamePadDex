import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old_start = s.index('    /* diagnostics: does the accessibility dump work from this process? */')
old_end = s.index('    out("CAP screen %d", readable);')
new = '''    /* diagnostics only: never block the command loop with a ~2 s dump */
    out("INFO uia %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);
    out("INFO worker %d", ({ FILE *wf = fopen(FOCUS_PID, "r"); int ok = 0;
        if (wf) { int p = 0; ok = (fscanf(wf, "%d", &p) == 1) && pid_is_worker((pid_t)p); fclose(wf); }
        ok; }));
'''
s = s[:old_start] + new + s[old_end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
