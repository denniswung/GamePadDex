import io, sys

BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
ENG = BASE + "EngineService.kt"
PREFS = BASE + "Prefs.kt"
ROOT = BASE + "RootInput.kt"
ACT = BASE + "Actions.kt"
HELPER = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"

def patch(path, old, new, count=1):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", path, old[:60].replace("\n", "\\n"))
        sys.exit(1)
    s = s.replace(old, new, count)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", path, old.splitlines()[0][:50])

eng = io.open(ENG, encoding="utf-8").read()

# ---------- 1. fields ----------
patch(ENG,
"""    private val DOUBLE_WINDOW = 320L
""",
"""    private val DOUBLE_WINDOW = 320L

    // --- v1.45 key state machine: GUIDE help / X+GUIDE force stop / SELECT+START ---
    private var guideDownAt = 0L
    private var guideHelpShown = false
    private var guideHelpRunnable: Runnable? = null
    private var forceRunnable: Runnable? = null
    private var forceArmed = false
    private var screenRunnable: Runnable? = null
    private var screenArmed = false
    /** continuous mix output (X+volume, X+LB/RB): start after 300 ms, repeat 100-150 ms */
    private var mixHoldAction = ""
    private var mixHoldKeys: List<String> = emptyList()
    private var mixHoldStartAt = 0L
    private var mixHoldNextAt = 0L
""")

# ---------- 2. handleSpecial call + functions ----------
patch(ENG,
"""        val wasDown = pressedButtons.contains(name)
        if (down == wasDown) return
        if (down) pressedButtons.add(name) else pressedButtons.remove(name)

        if (down) {""",
"""        val wasDown = pressedButtons.contains(name)
        if (down == wasDown) return
        if (down) pressedButtons.add(name) else pressedButtons.remove(name)

        if (handleSpecial(name, down)) return

        if (down) {""")

patch(ENG,
"""    /** repeat interval of the hold-scroll wheel (speed 1..10) */""",
"""    /**
     * GUIDE / X+GUIDE / SELECT+START state machine (spec: 手柄按键处理 §4/§5).
     * Returns true when the button was fully handled here.
     */
    private fun handleSpecial(name: String, down: Boolean): Boolean {
        if (name == "guide") {
            if (down) {
                guideDownAt = SystemClock.elapsedRealtime()
                guideHelpShown = false
                if (pressedButtons.contains("x")) startForceTimer() else startGuideHelpTimer()
            } else {
                cancelGuideHelp()
                cancelForce()
                if (guideHelpShown) {
                    guideHelpShown = false
                    Log.i(TAG, "guide help closed")
                }
                guideDownAt = 0L
            }
            return true
        }
        if (name == "x" && guideDownAt != 0L) {
            if (down) {
                if (!guideHelpShown) {
                    cancelGuideHelp()
                    startForceTimer()
                }
            } else {
                cancelForce()
            }
            // X belongs to the GUIDE chord here: suppress every other X semantic
            return true
        }
        if (name == "select" || name == "start") {
            if (down) {
                val other = if (name == "select") "start" else "select"
                if (pressedButtons.contains(other)) {
                    startScreenTimer()
                    return true
                }
                if (name == "start" && screenArmed) return true
            } else {
                if (screenArmed) {
                    cancelScreenTimer()
                    return true
                }
            }
        }
        return false
    }

    private fun startGuideHelpTimer() {
        cancelGuideHelp()
        val r = Runnable {
            guideHelpRunnable = null
            if (pressedButtons.contains("guide") && !pressedButtons.contains("x")) {
                guideHelpShown = true
                Log.i(TAG, "guide help")
                showHelpToast()
                vibrate(40)
            }
        }
        guideHelpRunnable = r
        handler.postDelayed(r, 800L)
    }

    private fun cancelGuideHelp() {
        guideHelpRunnable?.let { handler.removeCallbacks(it) }
        guideHelpRunnable = null
    }

    private fun startForceTimer() {
        cancelForce()
        cancelGuideHelp()
        forceArmed = true
        val r = Runnable {
            forceRunnable = null
            if (forceArmed && pressedButtons.contains("x") && pressedButtons.contains("guide")) {
                forceArmed = false
                Log.i(TAG, "force stop by X+GUIDE")
                actions.fire(Action.FORCE_STOP, "")
                vibrate(120)
                toast("已强制停止当前应用")
            }
        }
        forceRunnable = r
        handler.postDelayed(r, 1500L)
        Log.i(TAG, "force timer armed")
    }

    private fun cancelForce() {
        forceArmed = false
        forceRunnable?.let { handler.removeCallbacks(it) }
        forceRunnable = null
    }

    private fun startScreenTimer() {
        cancelScreenTimer()
        screenArmed = true
        val r = Runnable {
            screenRunnable = null
            if (screenArmed) {
                screenArmed = false
                Log.i(TAG, "select+start -> screen toggle")
                actions.fire(Action.POWER, "")
                vibrate(60)
                toast("屏幕开/关")
            }
        }
        screenRunnable = r
        handler.postDelayed(r, 1000L)
        Log.i(TAG, "select+start timer armed")
    }

    private fun cancelScreenTimer() {
        screenArmed = false
        screenRunnable?.let { handler.removeCallbacks(it) }
        screenRunnable = null
    }

    private fun showHelpToast() {
        val text = "手柄映射帮助\\n" +
            "A 左键/焦点  B 返回  X 修饰  Y Home\\n" +
            "LB 上滑  RB 下滑  LT/RT 缩放\\n" +
            "L3 居中  R3 静音/双击播放  SELECT 通知栏\\n" +
            "START 上个应用  SHARE 鼠标模式\\n" +
            "X+方向 音量/切歌  X+LB/RB 横滑\\n" +
            "X+GUIDE 1.5s 强停  SELECT+START 1s 开关屏"
        try {
            android.widget.Toast.makeText(this, text, android.widget.Toast.LENGTH_LONG).show()
        } catch (_: Throwable) {
        }
    }

    private fun toast(text: String) {
        try {
            android.widget.Toast.makeText(this, text, android.widget.Toast.LENGTH_SHORT).show()
        } catch (_: Throwable) {
        }
    }

    private fun vibrate(ms: Long) {
        try {
            val v = getSystemService(VIBRATOR_SERVICE) as android.os.Vibrator
            if (android.os.Build.VERSION.SDK_INT >= 26) {
                v.vibrate(android.os.VibrationEffect.createOneShot(ms, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION") v.vibrate(ms)
            }
        } catch (_: Throwable) {
        }
    }

    /** repeat interval of the hold-scroll wheel (speed 1..10) */""")

# ---------- 3. mix repeat: arm after firing ----------
patch(ENG,
"""            Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action")
            fireMixAction(action, prefs.mixValue(i))
            return true""",
"""            Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action")
            fireMixAction(action, prefs.mixValue(i))
            armMixRepeat(action, keys)
            return true""")

patch(ENG,
"""    private fun releaseMixFor(name: String) {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i] && prefs.mixKeys(i).contains(name)) mixFired[i] = false
        }
    }""",
"""    private fun releaseMixFor(name: String) {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i] && prefs.mixKeys(i).contains(name)) mixFired[i] = false
        }
        if (mixHoldAction.isNotEmpty() && mixHoldKeys.contains(name)) stopMixRepeat()
    }

    /** X+volume and X+LB/RB: first pulse now, then repeat after 300 ms */
    private fun armMixRepeat(action: String, keys: List<String>) {
        val repeat = action == Action.VOLUME_UP || action == Action.VOLUME_DOWN ||
            action == Action.WHEEL_LEFT || action == Action.WHEEL_RIGHT
        if (!repeat) return
        mixHoldAction = action
        mixHoldKeys = keys
        val now = SystemClock.elapsedRealtime()
        mixHoldStartAt = now + 300L
        mixHoldNextAt = mixHoldStartAt
    }

    private fun stopMixRepeat() {
        mixHoldAction = ""
        mixHoldKeys = emptyList()
    }

    private fun mixRepeatIntervalMs(): Long =
        if (mixHoldAction == Action.WHEEL_LEFT || mixHoldAction == Action.WHEEL_RIGHT) 120L else 100L

    private fun repeatMixHold() {
        when (mixHoldAction) {
            Action.VOLUME_UP -> actions.fire(Action.VOLUME_UP, "")
            Action.VOLUME_DOWN -> actions.fire(Action.VOLUME_DOWN, "")
            Action.WHEEL_LEFT -> fireSwipeOnce(1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(-1, 60)
        }
    }""")

# ---------- 4. mix WHEEL_LEFT/RIGHT use 60% width ----------
patch(ENG,
"""            Action.WHEEL_LEFT -> fireSwipeOnce(1)
            Action.WHEEL_RIGHT -> fireSwipeOnce(-1)""",
"""            Action.WHEEL_LEFT -> fireSwipeOnce(1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(-1, 60)""")

# ---------- 5. doSwipe width parameter ----------
patch(ENG,
"""    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false) {""",
"""    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false, widthPct: Int = 0) {""")

patch(ENG,
"""            val dist = if (slow) (w * 0.25f).toInt().coerceIn(320, 900)
            else (w * 0.4f).toInt().coerceIn(500, 1200)""",
"""            val dist = if (widthPct > 0) (w * widthPct / 100f).toInt().coerceIn(400, 1600)
            else if (slow) (w * 0.25f).toInt().coerceIn(320, 900)
            else (w * 0.4f).toInt().coerceIn(500, 1200)""")

patch(ENG,
"""    /** one-shot horizontal swipe used by mix slots / wheel-left-right actions */
    private fun fireSwipeOnce(dir: Int) = doSwipe(false, dir)""",
"""    /** one-shot horizontal swipe used by mix slots / wheel-left-right actions */
    private fun fireSwipeOnce(dir: Int, widthPct: Int = 0) = doSwipe(false, dir, false, widthPct)""")

# ---------- 6. step(): mix repeat + r3 double cancel + x double cancel on precision ----------
patch(ENG,
"""        val dead = prefs.deadzone / 1000f
        val dx = curve(axes[0], dead)""",
"""        if (mixHoldAction.isNotEmpty()) {
            val nowMix = SystemClock.elapsedRealtime()
            if (nowMix >= mixHoldStartAt && nowMix >= mixHoldNextAt) {
                mixHoldNextAt = nowMix + mixRepeatIntervalMs()
                repeatMixHold()
            }
        }
        // R3 double = play/pause: moving the right stick inside the window cancels it
        if (pendingDowns.containsKey("r3")) {
            val sd = prefs.scrollDeadzone / 1000f
            if (Math.abs(axes[12]) > sd || Math.abs(axes[13]) > sd) {
                pendingDowns.remove("r3")?.let { handler.removeCallbacks(it) }
                lastDownAt["r3"] = 0L
                Log.i(TAG, "double r3 cancelled (right stick moved)")
            }
        }
        val dead = prefs.deadzone / 1000f
        val dx = curve(axes[0], dead)""")

patch(ENG,
"""            for (k in deferredSingles.keys.toList()) {
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }""",
"""            for (k in deferredSingles.keys.toList()) {
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }
            // a stick used while X is held is the "slow pointer" chord:
            // the pending X double-press must not fire afterwards
            pendingDowns.remove("x")?.let { handler.removeCallbacks(it) }
            lastDownAt["x"] = 0L""")

io.open(ENG, "w", encoding="utf-8", newline="\n").write(eng)

# ---------- 7. Prefs: role swap ----------
p = io.open(PREFS, encoding="utf-8").read()
if 'val roleSwap' not in p:
    anchor = "    var modeOn: Boolean"
    add = """    /** true: left stick = slide/scroll, right stick = pointer (role swap, 通用文档 §4.1) */
    var roleSwap: Boolean
        get() = shared.getBoolean("role_swap", false)
        set(v) = shared.edit().putBoolean("role_swap", v).apply()

"""
    if anchor not in p:
        print("MISS prefs anchor"); sys.exit(1)
    p = p.replace(anchor, add + anchor, 1)
    io.open(PREFS, "w", encoding="utf-8", newline="\n").write(p)
    print("ok prefs roleSwap")

# ---------- 8. Actions: FORCE_STOP ----------
a = io.open(ACT, encoding="utf-8").read()
if 'FORCE_STOP' not in a:
    a = a.replace('    const val KEY_COMBO = "key_combo"',
                  '    const val KEY_COMBO = "key_combo"\n    const val FORCE_STOP = "force_stop"')
    a = a.replace('        RECENTS, HOME, BACK, NOTIFICATIONS, KEY_COMBO, NONE,',
                  '        RECENTS, HOME, BACK, NOTIFICATIONS, KEY_COMBO, FORCE_STOP, NONE,')
    io.open(ACT, "w", encoding="utf-8", newline="\n").write(a)
    print("ok actions FORCE_STOP")

# ---------- 9. RootInput: forceStopTop ----------
r = io.open(ROOT, encoding="utf-8").read()
if 'forceStopTop' not in r:
    r = r.replace('    fun closeApp() = send("L")',
                  '    fun closeApp() = send("L")\n\n    /** force-stop the current foreground package (root helper, whitelisted) */\n    fun forceStopTop() = send("f")')
    io.open(ROOT, "w", encoding="utf-8", newline="\n").write(r)
    print("ok root forceStopTop")

# ---------- 10. helper: 'f' command ----------
h = io.open(HELPER, encoding="utf-8").read()
if "case 'f'" not in h:
    anchor = "        case 'p': {"
    add = """        case 'f': {
            /* force-stop the current foreground package (whitelisted, root) */
            FILE *fp = popen("/system/bin/dumpsys activity activities 2>/dev/null | /system/bin/grep -m1 topResumedActivity | /system/bin/sed 's/.*u0 \\\\([^ ]*\\\\)\\\\/.*/\\\\1/'", "r");
            char pkg[192] = {0};
            if (fp) {
                if (!fgets(pkg, sizeof(pkg), fp)) pkg[0] = 0;
                pclose(fp);
            }
            char *nl = strchr(pkg, '\\n');
            if (nl) *nl = 0;
            if (pkg[0]) {
                char cmd[320];
                snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop %s", pkg);
                int rc = system(cmd);
                out("FORCE_STOP %s rc=%d", pkg, rc);
            } else {
                out("FORCE_STOP none");
            }
            break;
        }
"""
    if anchor not in h:
        print("MISS helper anchor"); sys.exit(1)
    h = h.replace(anchor, add + anchor, 1)
    io.open(HELPER, "w", encoding="utf-8", newline="\n").write(h)
    print("ok helper f")
print("done")
