import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
J = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse")

# ---------------- Prefs ----------------
pp = os.path.join(J, "Prefs.kt")
s = io.open(pp, encoding="utf-8").read()
if "val BUTTONS = listOf(" not in s:
    s = s.replace("""    /** mapping slots: x + (lb|rb|lt|rt|up|down|left|right) combos */""",
"""    /** every Xbox button that can be remapped on its own */
    val BUTTONS = listOf(
        "a", "b", "x", "y", "lb", "rb", "lt", "rt",
        "up", "down", "left", "right", "l3", "r3", "start", "select", "guide"
    )
    fun btnType(name: String) = "pref_btn_${name}_type"
    fun btnValue(name: String) = "pref_btn_${name}_value"

    const val COMBO_COUNT = 8
    fun comboKeys(i: Int) = "pref_combo_${i}_keys"
    fun comboType(i: Int) = "pref_combo_${i}_type"
    fun comboValue(i: Int) = "pref_combo_${i}_value"

    /** pseudo actions handled directly by the service */
    val EXTRA_ACTIONS = listOf("mouse_click", "back", "toggle_mouse", "scroll_up", "scroll_down")

    /** android key code for a button name (Xbox layout) */
    fun buttonKeycode(name: String): Int = when (name) {
        "a" -> 96; "b" -> 97; "x" -> 99; "y" -> 100
        "lb" -> 102; "rb" -> 103; "lt" -> 104; "rt" -> 105
        "up" -> 19; "down" -> 20; "left" -> 21; "right" -> 22
        "l3" -> 106; "r3" -> 107; "start" -> 108; "select" -> 109
        "guide" -> 110
        else -> -1
    }
    fun keycodeButton(code: Int): String? = BUTTONS.firstOrNull { buttonKeycode(it) == code }

    /** mapping slots: x + (lb|rb|lt|rt|up|down|left|right) combos */""", 1)
    io.open(pp, "w", encoding="utf-8", newline="\n").write(s)
    print("prefs ok")

# ---------------- Service ----------------
sp = os.path.join(J, "MouseAccessibilityService.kt")
s = io.open(sp, encoding="utf-8").read()

if "pressedButtons" not in s:
    s = s.replace("    private var hScrollDir = 0",
                  """    private var hScrollDir = 0

    /** key codes currently held, used for the full-key and combo mappings */
    private val pressedButtons = HashSet<Int>()
    private val firedCombos = HashSet<Int>()""", 1)

    # fireAction + mapping lookup helpers
    helpers = """
    /** runs a mapped action, including the pseudo actions handled here */
    private fun fireAction(action: String, value: String) {
        Log.i(TAG, "fireAction " + action + " " + value)
        when (action) {
            "mouse_click" -> engine?.let { it.onPrimaryDown(); it.onPrimaryUp() }
            "back" -> ActionDispatcher.back(this)
            "toggle_mouse" -> toggleMouseMode(!mouseMode)
            "scroll_up", "scroll_down" -> {
                val e = engine ?: return
                val dy = if (action == "scroll_up") 3f else -3f
                root?.pointScroll(e.pos.x, e.pos.y, dy, 0f, display?.displayId ?: 0)
            }
            else -> ActionDispatcher.run(this, prefs, action, value, "")
        }
        haptic(30L)
    }

    /** full-key + combo mapping. returns true when the key was consumed */
    private fun handleMappedButton(keyCode: Int, action: Int): Boolean {
        if (action == KeyEvent.ACTION_UP) {
            pressedButtons.remove(keyCode)
            return false
        }
        if (action != KeyEvent.ACTION_DOWN) return false
        pressedButtons.add(keyCode)
        // 1) combos first (all listed buttons must be held)
        for (i in 0 until Prefs.COMBO_COUNT) {
            val keys = prefs.getString(Prefs.comboKeys(i), "") ?: ""
            if (keys.isBlank()) continue
            val codes = keys.split("+").mapNotNull { Prefs.buttonKeycode(it.trim()) }
            if (codes.isEmpty()) continue
            val type = prefs.getString(Prefs.comboType(i), "none") ?: "none"
            if (type == "none" || type == "default") continue
            if (codes.all { pressedButtons.contains(it) }) {
                if (firedCombos.add(i)) {
                    fireAction(type, prefs.getString(Prefs.comboValue(i), "") ?: "")
                }
                return true
            }
        }
        // 2) single button mapping
        val name = Prefs.keycodeButton(keyCode) ?: return false
        val type = prefs.getString(Prefs.btnType(name), "default") ?: "default"
        if (type != "default" && type != "none") {
            fireAction(type, prefs.getString(Prefs.btnValue(name), "") ?: "")
            return true
        }
        return false
    }

"""
    s = s.replace("    // ------------------------------------------------------------- key input", helpers + "    // ------------------------------------------------------------- key input", 1)

    # hook it at the very start of handleKey (before the toggle/built-ins)
    s = s.replace("""    private fun handleKey(keyCode: Int, action: Int, repeat: Int): Boolean {
        val e = engine ?: return false""",
"""    private fun handleKey(keyCode: Int, action: Int, repeat: Int): Boolean {
        val e = engine ?: return false
        // user remaps win over the built-in behaviour; combos are checked inside
        if (handleMappedButton(keyCode, action)) return true
        if (action == KeyEvent.ACTION_UP) firedCombos.clear()""", 1)

    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("service ok")

# ---------------- strings ----------------
xp = os.path.join(root, "app", "src", "main", "res", "values", "strings_extra.xml")
x = io.open(xp, encoding="utf-8").read()
if "full_key_mapping_title" not in x:
    x = x.replace("</resources>", """    <string name="full_key_mapping_title">全键映射（Xbox 按键）</string>
    <string name="full_key_mapping_hint">每个按键都可以单独改动作；下面的组合键在所有按键都按住时触发，优先于单键映射。</string>
    <string name="combos_title">组合按键</string>
    <string name="action_default">默认行为（不修改）</string>
    <string name="combo_keys_title">选择组合键（可多选）</string>
    <string name="combo_row_format">组合 %1$d：%2$s</string>
    <string name="combo_empty">未设置</string>
</resources>""", 1)
    io.open(xp, "w", encoding="utf-8", newline="\n").write(x)
    print("strings ok")
