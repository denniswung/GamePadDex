import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

# 1) helper: report the default launcher package once per session
old_fn = '''/* package of the activity currently resumed on the focused display */'''
new_fn = '''/* package of the current HOME app (default launcher) */
static int read_home_package(char *out, size_t n) {
    out[0] = 0;
    FILE *p = popen("cmd package resolve-activity --brief -a android.intent.action.MAIN "
                    "-c android.intent.category.HOME 2>/dev/null", "r");
    if (!p) return 0;
    char buf[512];
    char last[512] = {0};
    while (fgets(buf, sizeof(buf), p)) {
        char *nl = strchr(buf, '\\n');
        if (nl) *nl = 0;
        if (buf[0]) snprintf(last, sizeof(last), "%s", buf);
    }
    pclose(p);
    char *slash = strchr(last, '/');
    if (slash) *slash = 0;
    if (last[0] == 0) return 0;
    snprintf(out, n, "%s", last);
    return 1;
}

/* package of the activity currently resumed on the focused display */'''
assert old_fn in src
src = src.replace(old_fn, new_fn, 1)

old_ready = '''        out("READY");'''
new_ready = '''        out("READY");
        {
            char home[160];
            if (read_home_package(home, sizeof(home))) out("HOME %s", home);
        }'''
assert old_ready in src
src = src.replace(old_ready, new_ready, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
