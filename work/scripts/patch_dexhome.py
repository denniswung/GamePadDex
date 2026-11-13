import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
# D: inject a key event on a display through /system/bin/input (shell uid can inject)
c = c.replace("""        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) injector_key(kd, kc);
            break;
        }""",
"""        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) {
                char cmd[160];
                snprintf(cmd, sizeof(cmd), "/system/bin/input -d %d keyevent %d", kd, kc);
                int rc = system(cmd);
                out("KEYON %d %d rc=%d", kd, kc, rc);
            }
            break;
        }
        case 'H': {
            int hd = 0;
            if (sscanf(line, "%d", &hd) == 1 && hd > 0) {
                char cmd[320];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1",
                    hd);
                int rc = system(cmd);
                out("HOMEDEX %d rc=%d", hd, rc);
            }
            break;
        }""", 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("helper D/H commands ok")

rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
if "fun dexHome(" not in r:
    r = r.replace("""    /** inject a key event on a specific display (root) */""",
"""    /** bring the home screen up on a specific display (DeX launcher) */
    fun dexHome(displayId: Int): Boolean {
        if (!isRunning) return false
        send("H $displayId")
        return helperReady
    }

    /** inject a key event on a specific display (root) */""", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput dexHome ok")

sp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
v = io.open(sp, encoding="utf-8").read()
if "dexHome" not in v:
    v = v.replace("""        when (keyCode) {
            KeyEvent.KEYCODE_HOME -> performGlobalAction(GLOBAL_ACTION_HOME)""",
"""        if (disp != 0 && keyCode == KeyEvent.KEYCODE_HOME && root?.helperReady == true) {
            root?.dexHome(disp)
            Log.i(TAG, "dex home on display " + disp)
            return
        }
        when (keyCode) {
            KeyEvent.KEYCODE_HOME -> performGlobalAction(GLOBAL_ACTION_HOME)""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service dexHome ok")