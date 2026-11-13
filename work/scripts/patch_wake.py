import io, sys
p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()
anchor = "static void scan_new_devices(void) {"
add = r'''static time_t g_last_wake_at = 0;
static int screen_awake(void) {
    FILE *f = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -m1 mWakefulness=", "r");
    char b[128] = {0};
    int awake = 0;
    if (f) {
        if (fgets(b, sizeof(b), f)) {
            if (strstr(b, "Awake")) awake = 1;
        }
        pclose(f);
    }
    return awake;
}
/* 通用文档 §6: wake the screen when a gamepad is connected (no unlock) */
static void maybe_wake_on_connect(const char *name) {
    time_t now = time(NULL);
    if (now - g_last_wake_at < 3) return;   /* 3 s debounce */
    int st = screen_awake();
    if (st == 1) {
        out("WAKE skip awake %s", name);
        return;
    }
    g_last_wake_at = now;
    system("/system/bin/input keyevent 224");   /* KEYCODE_WAKEUP */
    usleep(600 * 1000);
    out("WAKE_CONNECT %s (was %d now %d)", name, st, screen_awake());
}

'''
if "maybe_wake_on_connect" in s:
    print("already"); sys.exit(0)
if anchor not in s:
    print("MISS anchor"); sys.exit(1)
s = s.replace(anchor, add + anchor, 1)
# call it after a device is grabbed
s = s.replace('''        if (d->grabbed) out("GRABBED %d %s", d->id, d->name);
        g_ndev++;''',
'''        if (d->grabbed) out("GRABBED %d %s", d->id, d->name);
        maybe_wake_on_connect(d->name);
        g_ndev++;''', 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok wake")
