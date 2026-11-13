import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

old = '''    out("CAP focus %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);'''
new = '''    out("CAP focus %d", access("/system/bin/uiautomator", X_OK) == 0 ? 1 : 0);
    out("CAP apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
    /* diagnostics: does the accessibility dump work from this process? */
    {
        int rc = system("/system/bin/uiautomator dump --compressed /data/local/tmp/gpm_st.xml "
                        ">/data/adb/gpm/uia_selftest.log 2>&1");
        FILE *lf = fopen("/data/adb/gpm/uia_selftest.log", "r");
        char l1[160] = {0};
        if (lf) { if (!fgets(l1, sizeof(l1), lf)) l1[0] = 0; fclose(lf); }
        char *nl = strchr(l1, '\\n');
        if (nl) *nl = 0;
        out("CAP uia rc=%d %s", rc, l1);
    }'''
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
