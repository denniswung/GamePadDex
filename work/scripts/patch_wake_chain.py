import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
T = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(H, encoding="utf-8").read()

old = s[s.index("static void wake_key_once(void) {"):s.index("static void maybe_wake_on_connect(const char *name) {")]
new = '''static void wake_key_once(void) {
    /* 1) the virtual keyboard's KEY_WAKEUP (kernel-level, no exec) */
    if (g_kbd >= 0) {
        ev_emit(g_kbd, EV_KEY, 224 /* KEY_WAKEUP */, 1);
        ev_syn(g_kbd);
        usleep(60 * 1000);
        ev_emit(g_kbd, EV_KEY, 224, 0);
        ev_syn(g_kbd);
        usleep(500 * 1000);
        if (screen_awake() == 1) return;
    }
    /* 2) KEYCODE_WAKEUP through `input` (works from the root context) */
    system("/system/bin/input keyevent 224");
    usleep(500 * 1000);
    if (screen_awake() == 1) return;
    /* 3) last resort: PowerManager.wakeUp() via a global-namespace shell */
    system("/system/bin/su -M -c 'cmd power wakeup' </dev/null >/dev/null 2>&1");
    usleep(500 * 1000);
}

'''
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok wake")

# v145 asserts the legacy (task-bounds) geometry: run it with control focus off
t = io.open(T, encoding="utf-8").read()
marker = 'sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }'
if 'focus_scroll --ez bval false' not in t:
    t = t.replace(marker,
                  'sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }\n'
                  '# this suite checks the legacy task-bounds geometry\n'
                  'am broadcast -a com.dennis.dexpad.DEBUG -n com.dennis.dexpad/.DebugReceiver '
                  '--es pref focus_scroll --ez bval false >/dev/null 2>&1\n'
                  'sleep 0.5', 1)
    io.open(T, "w", encoding="utf-8", newline="\n").write(t)
    print("ok v145 focus off")
