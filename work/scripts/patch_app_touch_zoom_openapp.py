import io, sys, re

BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
R = BASE + "RootInput.kt"
E = BASE + "EngineService.kt"
A = BASE + "ActionRouter.kt"
AC = BASE + "Actions.kt"
P = BASE + "Prefs.kt"
C = BASE + "ConfigActivity.kt"


def load(p):
    return io.open(p, encoding="utf-8").read()


def save(p, s):
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)


def rep(s, old, new, tag):
    if old not in s:
        print("MISS", tag)
        sys.exit(1)
    return s.replace(old, new, 1)


# ---------------- RootInput ----------------
r = load(R)
if "fun touchSize" not in r:
    r = rep(r, '    fun forceStopTop() = send("f")', '''    fun forceStopTop() = send("f")

    /* ---- 虚拟触摸屏：点击 / 长按 / 双指缩放 ---- */

    /** 触摸面尺寸（像素），用于把屏幕坐标换算成触摸坐标 */
    fun touchSize(w: Int, h: Int) = send("q $w $h")

    /** 单指触摸 down/up（真实触摸事件，支持长按） */
    fun touch(x: Float, y: Float, down: Boolean) =
        send(String.format(Locale.US, "k %d %d %d", x.toInt(), y.toInt(), if (down) 1 else 0))

    /** 双指缩放：dir 1=放大 -1=缩小 0=停止 */
    fun pinch(dir: Int, x: Float, y: Float) =
        send(String.format(Locale.US, "l %d %d %d", dir, x.toInt(), y.toInt()))''', "rootinput")
    save(R, r)
    print("rootinput ok")
else:
    print("rootinput already")

# ---------------- Actions ----------------
a = load(AC)
if "OPEN_APP" not in a:
    a = rep(a, '    const val ZOOM_OUT = "zoom_out"             // CTRL + MINUS',
            '''    const val ZOOM_OUT = "zoom_out"             // CTRL + MINUS

    /** 打开指定应用（目标包名在设置页选择，默认不绑定任何按键） */
    const val OPEN_APP = "open_app"''', "actions const")
    a = rep(a, "        ZOOM_IN, ZOOM_OUT,", "        ZOOM_IN, ZOOM_OUT, OPEN_APP,", "actions all")
    a = rep(a, '        ZOOM_OUT -> "缩小（Ctrl + -）"',
            '''        ZOOM_OUT -> "缩小（Ctrl + -）"
        OPEN_APP -> "打开目标应用"''', "actions label")
    save(AC, a)
    print("actions ok")
else:
    print("actions already")

# ---------------- Prefs ----------------
p = load(P)
if "targetPackage" not in p:
    p = rep(p, '        const val KEY_CENTER_GAIN = "center_gain"',
            '''        const val KEY_CENTER_GAIN = "center_gain"
        const val KEY_TARGET_PACKAGE = "target_package"''', "prefs const")
    p = rep(p, "    /** 居中时 raw 单位 → 屏幕像素 的增益",
            '''    /** "打开目标应用"动作要启动的包名（空 = 未设置） */
    var targetPackage: String
        get() = shared.getString(KEY_TARGET_PACKAGE, "") ?: ""
        set(v) = shared.edit().putString(KEY_TARGET_PACKAGE, v).apply()

    /** 居中时 raw 单位 → 屏幕像素 的增益''', "prefs prop")
    p = rep(p, "        o.put(KEY_IDLE_HIDE_SEC, idleHideSec)",
            '''        o.put(KEY_IDLE_HIDE_SEC, idleHideSec)
        o.put(KEY_TARGET_PACKAGE, targetPackage)''', "prefs export")
    save(P, p)
    print("prefs ok")
else:
    print("prefs already")

# ---------------- ActionRouter ----------------
ar = load(A)
if "Action.OPEN_APP ->" not in ar:
    ar = rep(ar, "        /** the pointer must be visible again (e.g. it was hidden while idle) */",
             '''        /** 启动"目标应用"动作里配置的包 */
        fun launchApp(pkg: String)

        /** the pointer must be visible again (e.g. it was hidden while idle) */''', "router iface")
    ar = rep(ar, "            Action.ZOOM_IN -> combo(display, \"zoom in\", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_PLUS)",
             '''            Action.OPEN_APP -> {
                val pkg = prefs.targetPackage
                if (pkg.isBlank()) log("open app: 目标应用未设置")
                else {
                    host.launchApp(pkg)
                    log("open app $pkg")
                }
            }
            // 缩放：普通模式由引擎用双指手势（以光标为基准，按住连续）；
            // 只有 d-pad 原生导航模式才用 Ctrl +/- 快捷键
            Action.ZOOM_IN -> combo(display, "zoom in (d-pad mode)", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_PLUS)''', "router open app")
    save(A, ar)
    print("router ok")
else:
    print("router already")

# ---------------- EngineService ----------------
e = load(E)

if "leftIsTouch" not in e:
    e = rep(e, "    private var pointerHidden = false",
            '''    private var pointerHidden = false
    /** 当前 A 键按下走的是"触摸点击"（而不是鼠标左键） */
    private var leftIsTouch = false
    /** 最近一次下发给助手的触摸面尺寸 */
    private var touchSizeSent = ""''', "engine fields")

    # LEFT 按下：触摸点击
    e = rep(e, '''            Action.LEFT -> {
                if (navActive()) {
                    // native d-pad navigation: A activates the focused control
                    // instead of clicking at the (untouched) cursor position
                    root.pointKey(activeDisplay(), KeyEvent.KEYCODE_DPAD_CENTER)
                    Log.i(TAG, "A -> DPAD_CENTER (native nav)")
                } else {
                    root.button(0, true)
                    pressedMouse.add(0)
                    Log.i(TAG, "left button down")
                }
            }''', '''            Action.LEFT -> {
                if (navActive()) {
                    // native d-pad navigation: A activates the focused control
                    // instead of clicking at the (untouched) cursor position
                    root.pointKey(activeDisplay(), KeyEvent.KEYCODE_DPAD_CENTER)
                    Log.i(TAG, "A -> DPAD_CENTER (native nav)")
                } else {
                    // 鼠标左键 = 在光标位置模拟一次屏幕点击（真实触摸事件，
                    // 按住不放就是长按）；这样信息流/短剧类应用也认得
                    val (px, py) = pointerPos()
                    showPointer()
                    root.touch(px, py, true)
                    leftIsTouch = true
                    pressedMouse.add(0)
                    Log.i(TAG, "left touch down at ${px.toInt()},${py.toInt()}")
                }
            }''', "engine left down")

    # LEFT 抬起
    e = rep(e, '''            Action.LEFT -> {
                if (navActive()) {
                    // the press was translated into DPAD_CENTER, nothing to release
                    pressedMouse.remove(0)
                } else {
                    root.button(0, false)
                    pressedMouse.remove(0)
                }
            }''', '''            Action.LEFT -> {
                if (navActive()) {
                    // the press was translated into DPAD_CENTER, nothing to release
                    pressedMouse.remove(0)
                } else if (leftIsTouch) {
                    val (px, py) = pointerPos()
                    root.touch(px, py, false)
                    leftIsTouch = false
                    pressedMouse.remove(0)
                    Log.i(TAG, "left touch up at ${px.toInt()},${py.toInt()}")
                } else {
                    root.button(0, false)
                    pressedMouse.remove(0)
                }
            }''', "engine left up")

    # ZOOM：普通模式用双指手势
    zoom_anchor = '''            Action.ZOOM_IN, Action.ZOOM_OUT -> {
                if (navActive()) {
                    actions.fire(mapped, "")
                } else {
                    val (px, py) = pointerPos()
                    root.pinch(if (mapped == Action.ZOOM_IN) 1 else -1, px, py)
                    zooming = true
                    Log.i(TAG, "pinch zoom ${if (mapped == Action.ZOOM_IN) "in" else "out"} at ${px.toInt()},${py.toInt()}")
                }
            }
'''
    if "pinch zoom" not in e:
        # 插到 fireSingle 的 WHEEL_UP 分支前
        e = rep(e, "            Action.WHEEL_UP -> wheelHold = 1", zoom_anchor + "            Action.WHEEL_UP -> wheelHold = 1", "engine zoom down")

    if "private var zooming = false" not in e:
        e = rep(e, "    private var leftIsTouch = false", "    private var leftIsTouch = false\n    private var zooming = false", "engine zoom flag")

    # 缩放抬起
    if "Action.ZOOM_IN, Action.ZOOM_OUT -> root.pinch(0, 0f, 0f)" not in e:
        e = rep(e, "            Action.WHEEL_UP, Action.WHEEL_DOWN -> wheelHold = 0",
                '''            Action.ZOOM_IN, Action.ZOOM_OUT -> {
                if (zooming) {
                    root.pinch(0, 0f, 0f)
                    zooming = false
                    Log.i(TAG, "pinch zoom stop")
                }
            }
            Action.WHEEL_UP, Action.WHEEL_DOWN -> wheelHold = 0''', "engine zoom up")

    # 辅助函数：光标位置 / 触摸面尺寸刷新 / 启动目标应用
    e = rep(e, "    private fun navActive(): Boolean =",
            '''    /** 光标当前位置（引擎跟踪值），用于触摸点击 / 双指缩放的基准点 */
    private fun pointerPos(): Pair<Float, Float> {
        val (vw, vh) = displaySize(activeDisplay())
        val cx = if (ptrX.isNaN()) vw / 2f else ptrX
        val cy = if (ptrY.isNaN()) vh / 2f else ptrY
        return Pair(
            cx.coerceIn(0f, vw.toFloat()),
            cy.coerceIn(0f, vh.toFloat()),
        )
    }

    /** 把触摸面尺寸同步给助手（旋转/分辨率变化时重发） */
    private fun syncTouchSize() {
        if (!root.helperReady) return
        val (vw, vh) = displaySize(activeDisplay())
        val key = "${vw}x$vh"
        if (key != touchSizeSent) {
            touchSizeSent = key
            root.touchSize(vw, vh)
        }
    }

    /** "打开目标应用"动作 */
    fun launchTargetApp(pkg: String) {
        try {
            val i = packageManager.getLaunchIntentForPackage(pkg)
            if (i == null) {
                Log.w(TAG, "open app: no launch intent for $pkg")
                toast("找不到应用 $pkg")
                return
            }
            i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(i)
        } catch (t: Throwable) {
            Log.w(TAG, "open app failed: ${t.message}")
        }
    }

    private fun navActive(): Boolean =''', "engine helpers")

    # 引擎 host 实现：launchApp
    e = rep(e, "            override fun onPointerNeeded() {",
            '''            override fun launchApp(pkg: String) = launchTargetApp(pkg)

            override fun onPointerNeeded() {''', "engine host launch")

    save(E, e)
    print("engine ok")
else:
    print("engine already")

# ---------------- ConfigActivity ----------------
c = load(C)
if "选择目标应用" not in c:
    if "import android.app.AlertDialog" not in c:
        c = c.replace("import android.os.Bundle", "import android.app.AlertDialog\nimport android.content.Intent\nimport android.os.Bundle", 1)
    c = rep(c, "    private fun buildPointer() {",
            '''    /** "打开目标应用"动作的目标包名选择器 */
    private fun buildTargetApp() {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
            isClickable = true
        }
        row.addView(android.widget.TextView(this).apply {
            text = "打开目标应用"
            textSize = 16f
            setTextColor(0xFF202124.toInt())
        })
        row.addView(android.widget.TextView(this).apply {
            val pkg = prefs.targetPackage
            text = if (pkg.isBlank()) "未设置（点击选择）" else pkg
            textSize = 13f
            setTextColor(0xFF5F6368.toInt())
        })
        row.setOnClickListener { pickTargetApp() }
        content.addView(card(row))
    }

    private fun pickTargetApp() {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = pm.queryIntentActivities(intent, 0)
            .map { it.loadLabel(pm).toString() to it.activityInfo.packageName }
            .distinctBy { it.second }
            .sortedBy { it.first }
        if (apps.isEmpty()) {
            android.widget.Toast.makeText(this, "没有可启动的应用", android.widget.Toast.LENGTH_SHORT).show()
            return
        }
        val items = apps.map { "${it.first}\\n${it.second}" }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("选择目标应用")
            .setItems(items) { _, i ->
                prefs.targetPackage = apps[i].second
                rebuild()
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun buildPointer() {''', "config picker")
    c = rep(c, "        buildGeneral()", "        buildGeneral()\n        buildTargetApp()", "config call")
    save(C, c)
    print("config ok")
else:
    print("config already")
