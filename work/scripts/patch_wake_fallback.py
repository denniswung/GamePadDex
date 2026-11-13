import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()

old = '''    g_last_wake_at = now;
    system("input keyevent 224");                    /* KEYCODE_WAKEUP */
    out("WAKE_CONNECT %s %s (was %d)", path, name, st);'''
new = '''    g_last_wake_at = now;
    system("input keyevent 224");                    /* KEYCODE_WAKEUP */
    usleep(400 * 1000);
    if (screen_awake() != 1) {
        /* some ROMs ignore WAKEUP while dozing; POWER still wakes */
        system("input keyevent 26");
        out("WAKE_CONNECT fallback POWER (%s)", name);
        usleep(300 * 1000);
    }
    out("WAKE_CONNECT %s %s (was %d, now %d)", path, name, st, screen_awake());'''
assert old in s
s = s.replace(old, new, 1)

old2 = '''        case 'k': {
            system("input keyevent 224");
            out("WAKE");
            break;
        }'''
new2 = '''        case 'k': {
            system("input keyevent 224");
            usleep(300 * 1000);
            if (screen_awake() != 1) system("input keyevent 26");
            out("WAKE %d", screen_awake());
            break;
        }'''
assert old2 in s
s = s.replace(old2, new2, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("wake fallback patched")
