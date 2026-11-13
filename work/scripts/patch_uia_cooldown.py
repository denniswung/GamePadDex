import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# 1) worker: cooldown after every dump so UiAutomation can unregister
rep('''    "    /system/bin/uiautomator dump --compressed " FOCUS_UI
        " >/data/adb/gpm/worker.log 2>&1\\n"
    "    touch " FOCUS_DONE "\\n"''',
    '''    "    /system/bin/uiautomator dump --compressed " FOCUS_UI
        " >/data/adb/gpm/worker.log 2>&1\\n"
    "    touch " FOCUS_DONE "\\n"
    "    sleep 3\\n"''', "worker cooldown")

# 2) helper: at most one request every 5 s (a failed dump must not retry-storm)
rep("static long long g_last_input_ms = 0;",
    "static long long g_last_input_ms = 0;\n"
    "/* uiautomator registers a UiAutomation service; asking again too soon makes\n"
    " * it die with \"already registered\" (seen as a FATAL EXCEPTION) */\n"
    "static long long g_last_dump_req_ms = 0;", "req stamp")

rep('''static int focus_dump(void) {
    focus_shell_ensure();''',
    '''static int focus_dump(void) {
    if (g_last_dump_req_ms != 0 && now_ms() - g_last_dump_req_ms < 5000) return -1;
    g_last_dump_req_ms = now_ms();
    focus_shell_ensure();''', "dump spacing")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("done")
