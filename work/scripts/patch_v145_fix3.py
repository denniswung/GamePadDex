import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
old = s[s.index("/* 通用文档 §6: wake the screen"):s.index("static void scan_new_devices(void) {")]
new = """/* 通用文档 §6: wake the screen when a gamepad is connected (no unlock).
 * The virtual keyboard's KEY_WAKEUP is used first (uinput, SELinux-safe);
 * KEYCODE_WAKEUP via `input` is only a fallback. */
static void wake_key_once(void) {
    if (g_kbd >= 0) {
        ev_emit(g_kbd, EV_KEY, 224 /* KEY_WAKEUP */, 1);
        ev_syn(g_kbd);
        usleep(60 * 1000);
        ev_emit(g_kbd, EV_KEY, 224, 0);
        ev_syn(g_kbd);
    } else {
        system("/system/bin/input keyevent 224");
    }
}
static void maybe_wake_on_connect(const char *name) {
    time_t now = time(NULL);
    if (now - g_last_wake_at < 3) return;   /* 3 s debounce */
    int st = screen_awake();
    if (st == 1) {
        out("WAKE skip awake %s", name);
        return;
    }
    g_last_wake_at = now;
    wake_key_once();
    usleep(600 * 1000);
    if (screen_awake() != 1) {
        wake_key_once();
        usleep(600 * 1000);
    }
    out("WAKE_CONNECT %s (was %d now %d)", name, st, screen_awake());
}

"""
s = s.replace(old, new)
io.open(h, "w", encoding="utf-8", newline="\n").write(s)

v = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/vgpad.c"
z = io.open(v, encoding="utf-8").read()
if "r3rstick" not in z:
    z = z.replace('    } else if (!strcmp(argv[1], "dblstick")) {',
'''    } else if (!strcmp(argv[1], "r3rstick")) {
        // r3rstick <axis> <value> <pre>: one R3 press, then move the right stick at once
        int axis = atoi(argv[2]);
        int val = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, 318, 1); syn(); sleep_ms(40);
        emit(EV_KEY, 318, 0); syn();
        sleep_ms(50);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(250);
        emit(EV_ABS, axis, 0); syn();
    } else if (!strcmp(argv[1], "dblstick")) {''')
    io.open(v, "w", encoding="utf-8", newline="\n").write(z)
print("ok")
