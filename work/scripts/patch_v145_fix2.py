import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
s = s.replace('snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop %s", pkg);',
              'snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop --user 0 %s", pkg);')
s = s.replace("""    g_last_wake_at = now;
    system("/system/bin/input keyevent 224");   /* KEYCODE_WAKEUP */
    usleep(600 * 1000);
    out("WAKE_CONNECT %s (was %d now %d)", name, st, screen_awake());""",
"""    g_last_wake_at = now;
    system("/system/bin/input keyevent 224");   /* KEYCODE_WAKEUP */
    usleep(600 * 1000);
    if (screen_awake() != 1) {
        /* a second WAKEUP is harmless; POWER would toggle an already-on screen */
        system("/system/bin/input keyevent 224");
        usleep(600 * 1000);
    }
    out("WAKE_CONNECT %s (was %d now %d)", name, st, screen_awake());""")
io.open(h, "w", encoding="utf-8", newline="\n").write(s)

t = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
x = io.open(t, encoding="utf-8").read()
old_start = x.index("# ---- R3 double + cancel on right stick ----")
old_end = x.index("# ---- GUIDE help")
x = x[:old_start] + """# ---- R3 double + cancel on right stick ----
logcat -c
for i in 1 2 3; do
    L=$(hcount)
    $VG double 318 60 110 2500 >/dev/null 2>&1
    sleep 0.6
    hl "$L" | grep -q 'KEYON 0 85' && break
done
hl "$L" | grep -q 'KEYON 0 85' && ok "K-12 R3 double play/pause" || bad "K-12 R3 double"
logcat -c
L=$(hcount)
$VG holdstick 318 4 20000 400 2500 >/dev/null 2>&1
sleep 0.5
if log | grep -q 'double r3 cancelled' && ! hl "$L" | grep -q 'KEYON 0 85'; then
    ok "K-12 R3 double cancelled by stick"
else
    bad "K-12 R3 cancel (cancel=$(log | grep -c 'double r3 cancelled') play=$(hl "$L" | grep -c 'KEYON 0 85'))"
fi

""" + x[old_end:]
x = x.replace("for i in 1 2 3; do\n    $VG hatkey 1 304 2500 >/dev/null 2>&1\n    sleep 0.4\n    hl \"$L\" | grep -q 'KEYON 0 23' && break\ndone",
"for i in 1 2 3 4; do\n    L=$(hcount)\n    $VG hatkey 1 304 2500 >/dev/null 2>&1\n    sleep 0.5\n    hl \"$L\" | grep -q 'KEYON 0 23' && break\ndone")
io.open(t, "w", encoding="utf-8", newline="\n").write(x)
print("ok")
