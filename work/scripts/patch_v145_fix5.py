import io
# helper: cmd power wakeup first
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
s = s.replace('system("/system/bin/input keyevent 224");\n    }', 'system("/system/bin/cmd power wakeup");\n    }', 1)
if "/system/bin/cmd power wakeup" not in s:
    s = s.replace("""    } else {
        system("/system/bin/input keyevent 224");
    }""",
"""    } else {
        system("/system/bin/cmd power wakeup");
    }""", 1)
s = s.replace("""    g_last_wake_at = now;
    wake_key_once();
    usleep(600 * 1000);
    if (screen_awake() != 1) {
        wake_key_once();
        usleep(600 * 1000);
    }""",
"""    g_last_wake_at = now;
    wake_key_once();
    usleep(600 * 1000);
    if (screen_awake() != 1) {
        system("/system/bin/cmd power wakeup");
        usleep(600 * 1000);
    }""")
io.open(h, "w", encoding="utf-8", newline="\n").write(s)

# tests
t = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
x = io.open(t, encoding="utf-8").read()
start = x.index("logcat -c\nL=$(hcount)\nfor i in 1 2 3 4; do")
end = x.index("# ---- L3 centre")
x = x[:start] + """logcat -c
$VG key 307 5000 2500 >/dev/null 2>&1 &
sleep 3.2
$VG hat 0 1 400 2500 >/dev/null 2>&1
sleep 0.6
$VG key 304 200 2500 >/dev/null 2>&1
sleep 0.8
log | grep -q 'A -> DPAD_CENTER' && ok "K-01 D-pad then A = focus" || bad "K-01 A focus"

""" + x[end:]

start = x.index('logcat -c\nL=$(hcount)\n$VG holdstick 318 4 20000 400 2500')
end = x.index("# ---- GUIDE help")
x = x[:start] + """logcat -c
L=$(hcount)
$VG r3rstick 4 20000 2500 >/dev/null 2>&1
sleep 0.5
if log | grep -q 'double r3 cancelled' && ! hl "$L" | grep -q 'KEYON 0 85'; then
    ok "K-12 R3 double cancelled by stick"
else
    bad "K-12 R3 cancel (cancel=$(log | grep -c 'double r3 cancelled') play=$(hl "$L" | grep -c 'KEYON 0 85'))"
fi

""" + x[end:]

x = x.replace("""if hl "$L" | grep -q 'FORCE_STOP' && ! dumpsys activity activities 2>/dev/null | grep -q 'topResumedActivity.*com.android.settings'; then""",
"""sleep 1.2
if hl "$L" | grep -q 'FORCE_STOP' && [ -z "$(pidof com.android.settings)" ]; then""")
io.open(t, "w", encoding="utf-8", newline="\n").write(x)
print("ok")
