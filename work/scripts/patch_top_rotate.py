import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

# 1) top-package reader + rotation command, inserted before cmd_close_app
anchor = "/* close the currently focused app on the phone: L"
assert anchor in src
helper = '''/* package of the activity currently resumed on the focused display */
static int read_top_package(char *out, size_t n) {
    out[0] = 0;
    FILE *p = popen("dumpsys activity activities 2>/dev/null", "r");
    if (!p) return 0;
    char buf[2048];
    char comp[160] = {0};
    while (fgets(buf, sizeof(buf), p)) {
        char *t = strstr(buf, "topResumedActivity=ActivityRecord{");
        if (!t) continue;
        char *u0 = strstr(t, " u0 ");
        if (!u0) continue;
        sscanf(u0 + 4, "%159s", comp);
        break;
    }
    pclose(p);
    char *slash = strchr(comp, '/');
    if (slash) *slash = 0;
    if (comp[0] == 0) return 0;
    snprintf(out, n, "%s", comp);
    return 1;
}

/* force the phone orientation: 0 portrait, 1 landscape, -1 back to automatic */
static void cmd_rotation(int rot) {
    char cmd[256];
    if (rot < 0) {
        snprintf(cmd, sizeof(cmd), "settings put system accelerometer_rotation 1");
    } else {
        snprintf(cmd, sizeof(cmd),
                 "settings put system accelerometer_rotation 0; "
                 "settings put system user_rotation %d", rot);
    }
    out("ROTATION %d", rot);
    system(cmd);
}

'''
src = src.replace(anchor, helper + anchor, 1)

# 2) decl in the session loop
old_decl = "    time_t last_scan = time(NULL);\n    int last_dex = dex_display_id();"
assert old_decl in src
src = src.replace(old_decl, "    time_t last_scan = time(NULL);\n    int last_dex = dex_display_id();\n    char last_top[160] = {0};", 1)

# 3) report TOP changes every scan
old_scan = "            scan_new_devices();\n            ping_client();"
assert old_scan in src
src = src.replace(old_scan,
    "            scan_new_devices();\n"
    "            ping_client();\n"
    "            {\n"
    "                char topnow[160];\n"
    "                if (read_top_package(topnow, sizeof(topnow)) &&\n"
    "                    strcmp(topnow, last_top) != 0) {\n"
    "                    snprintf(last_top, sizeof(last_top), \"%s\", topnow);\n"
    "                    out(\"TOP %s\", last_top);\n"
    "                }\n"
    "            }", 1)

# 4) R command
old_case = "        case 'U':\n            ungrab_all();\n            break;"
assert old_case in src
src = src.replace(old_case,
    "        case 'U':\n            ungrab_all();\n            break;\n"
    "        case 'R': {\n"
    "            int rot = 0;\n"
    "            if (sscanf(line, \"%d\", &rot) == 1) cmd_rotation(rot);\n"
    "            break;\n"
    "        }", 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("patched")
