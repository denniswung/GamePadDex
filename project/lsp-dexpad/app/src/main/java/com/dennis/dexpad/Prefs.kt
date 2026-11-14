package com.dennis.dexpad

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/** Small, typed wrapper around the module preferences. */
class Prefs(context: Context) {

    companion object {
        const val NAME = "dexpad"

        const val KEY_ENABLED = "enabled"
        const val KEY_SPEED_DEX = "speed_dex"
        const val KEY_SPEED_PHONE = "speed_phone"
        const val KEY_DEADZONE = "deadzone"
        const val KEY_SCROLL_DEADZONE = "scroll_deadzone"
        const val KEY_SCROLL_SPEED = "scroll_speed"
        const val KEY_HSWIPE_SPEED = "hswipe_speed"
        const val KEY_PRECISION = "precision_scale"
        const val KEY_INVERT_SCROLL = "invert_scroll"
        const val KEY_VTOUCH = "v_touch_scroll"
        const val KEY_ARROW_MOVE = "arrow_moves_pointer"
        const val KEY_ARROW_STEP = "arrow_step"
        /** user's mouse-mode switch (SHARE); survives service restarts */
        const val KEY_MODE_ON = "mode_on"
        /** force the phone into landscape while the module is running */
        const val KEY_FORCE_LANDSCAPE = "force_landscape"
        /** hold-scroll wheel speed, 1 (slow) .. 10 (fast) */
        const val KEY_WHEEL_SPEED = "wheel_speed"

        /** every physical control the helper can report (keys + dpad/trigger axes) */
        val BUTTONS = listOf(
            "a", "b", "x", "y",
            "lb", "rb", "lt", "rt",
            "up", "down", "left", "right",
            "l3", "r3", "start", "select", "guide", "share",
        )

        /** number of multi-button mix slots (each button can own many combos) */
        const val MIX_COUNT = 24

        fun btnKey(button: String) = "btn_$button"

        fun comboKey(button: String) = "combo_$button"

        fun mixKeysKey(i: Int) = "mix_${i}_keys"

        fun mixActionKey(i: Int) = "mix_${i}_action"

        fun mixValueKey(i: Int) = "mix_${i}_value"

        fun longKey(button: String) = "lng_$button"

        const val KEY_LONG_MS = "long_ms"
        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"
        const val KEY_IDLE_HIDE_SEC = "idle_hide_sec"
        const val KEY_CENTER_GAIN = "center_gain"
        const val KEY_SENS_X = "sens_x"
        const val KEY_SENS_Y = "sens_y"
        const val KEY_EDGE_SLOW = "edge_slow"

        const val DEFAULT_COMBO = "alt+tab"

        /**
         * Defaults frozen from the user's tuned setup on 2026-11-06
         * (speeds 30/30, deadzone 16 %, scroll 4, B=back X=recents Y=home,
         * START=win+=, GUIDE=alt+f4, SHARE=toggle, SELECT=maximize, LT/RT=zoom).
         */
        fun defaultAction(button: String): String = when (button) {
            "a" -> Action.LEFT
            "b" -> Action.BACK
            "x" -> Action.NONE
            "y" -> Action.HOME
            // 用户习惯：RB = 向下浏览（手指上滑），LB = 向上回溯（手指下滑）
            "lb" -> Action.SCROLL_SWIPE_DOWN
            "rb" -> Action.SCROLL_SWIPE_UP
            "share" -> Action.TOGGLE
            "lt" -> Action.ZOOM_OUT
            "rt" -> Action.ZOOM_IN
            "l3" -> Action.CENTER_CURSOR
            "r3" -> Action.VOLUME_MUTE
            "start" -> Action.SWITCH_APP
            "select" -> Action.NOTIFICATIONS
            "guide" -> Action.FORCE_STOP   // Xbox 键 = 杀掉前台应用
            // d-pad = system arrow keys: they move the focused selection
            // (list/grid navigation) instead of moving the mouse pointer
            "up" -> Action.ARROW_UP
            "down" -> Action.ARROW_DOWN
            "left" -> Action.ARROW_LEFT
            "right" -> Action.ARROW_RIGHT
            else -> Action.NONE
        }

        /** per-button default shortcut (used when the action is [Action.KEY_COMBO]) */
        fun defaultCombo(button: String): String = when (button) {
            "x" -> "alt+tab"
            "y" -> "ctrl+a"
            "start" -> "alt+tab"
            "guide" -> "alt+f4"
            else -> DEFAULT_COMBO
        }

        /** default double-press action (X = recents, R3 = play/pause) */
        fun defaultDoubleAction(button: String): String = when (button) {
            "x" -> Action.RECENTS
            "r3" -> Action.PLAY_PAUSE
            else -> Action.NONE
        }

        /** default key set of mix slot [i] as a "+"-joined string */
        fun defaultMixKeys(i: Int): String = when (i) {
            0 -> "x+up"
            1 -> "x+down"
            2 -> "x+left"
            3 -> "x+right"
            4 -> "x+lb"
            5 -> "x+rb"
            // Y + L3 = 开/关屏幕（模拟电源键）
            9 -> "y+l3"
            else -> ""
        }

        fun defaultMixAction(i: Int): String = when (i) {
            0 -> Action.VOLUME_UP
            1 -> Action.VOLUME_DOWN
            2 -> Action.PREV_TRACK
            3 -> Action.NEXT_TRACK
            4 -> Action.WHEEL_LEFT    // X + LB = 向左滑动（上一页）
            5 -> Action.WHEEL_RIGHT   // X + RB = 向右滑动（下一页）
            9 -> Action.POWER         // Y + L3 = 开/关屏幕
            else -> Action.NONE
        }

        fun defaultMixValue(i: Int): String = DEFAULT_COMBO

        fun buttonLabel(button: String): String = when (button) {
            "a" -> "A"
            "b" -> "B"
            "x" -> "X"
            "y" -> "Y"
            "lb" -> "LB"
            "rb" -> "RB"
            "lt" -> "LT（左扳机）"
            "rt" -> "RT（右扳机）"
            "up" -> "十字键 ↑"
            "down" -> "十字键 ↓"
            "left" -> "十字键 ←"
            "right" -> "十字键 →"
            "l3" -> "L3（左摇杆按下）"
            "r3" -> "R3（右摇杆按下）"
            "start" -> "START"
            "select" -> "SELECT"
            "guide" -> "GUIDE（Xbox 键）"
            "share" -> "SHARE（分享键）"
            else -> button.uppercase()
        }
    }

    val shared: SharedPreferences = context.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    var enabled: Boolean
        get() = shared.getBoolean(KEY_ENABLED, true)
        set(v) = shared.edit().putBoolean(KEY_ENABLED, v).apply()

    /** pixels per 16 ms frame on the phone screen */
    var speedPhone: Int
        get() = shared.getInt(KEY_SPEED_PHONE, 30)
        set(v) = shared.edit().putInt(KEY_SPEED_PHONE, v).apply()

    /**
     * X + left stick precision mode: pointer speed in percent of the normal
     * speed (5..50, default 15).
     */
    var precisionScale: Int
        get() = shared.getInt(KEY_PRECISION, 15)
        set(v) = shared.edit().putInt(KEY_PRECISION, v).apply()

    /** per-mille of the stick travel that is ignored (0..400) */
    var deadzone: Int
        get() = shared.getInt(KEY_DEADZONE, 160)
        set(v) = shared.edit().putInt(KEY_DEADZONE, v).apply()

    /**
     * Separate, larger dead zone for the scrolling sticks (per-mille, 50..600).
     * Scrolling triggers only after a deliberate deflection, so a drifting or
     * lightly touched right stick never scrolls by itself.
     */
    var scrollDeadzone: Int
        get() = shared.getInt(KEY_SCROLL_DEADZONE, 350)
        set(v) = shared.edit().putInt(KEY_SCROLL_DEADZONE, v.coerceIn(50, 600)).apply()

    /** wheel notches per second at full stick deflection, 1..10 */
    var scrollSpeed: Int
        get() = shared.getInt(KEY_SCROLL_SPEED, 4)
        set(v) = shared.edit().putInt(KEY_SCROLL_SPEED, v).apply()

    /** horizontal swipe speed, 1 (slow) .. 10 (fast); default 7 */
    var hswipeSpeed: Int
        get() = shared.getInt(KEY_HSWIPE_SPEED, 7).coerceIn(1, 10)
        set(v) = shared.edit().putInt(KEY_HSWIPE_SPEED, v.coerceIn(1, 10)).apply()

    var invertScroll: Boolean
        get() = shared.getBoolean(KEY_INVERT_SCROLL, false)
        set(v) = shared.edit().putBoolean(KEY_INVERT_SCROLL, v).apply()

    /** vertical scrolling uses a real touch drag (smooth paging) instead of REL_WHEEL */
    var vTouchScroll: Boolean
        get() = shared.getBoolean(KEY_VTOUCH, true)
        set(v) = shared.edit().putBoolean(KEY_VTOUCH, v).apply()

    /** arrow keys also move the mouse cursor one step (default off: focus only) */
    var arrowMovesPointer: Boolean
        get() = shared.getBoolean(KEY_ARROW_MOVE, false)
        set(v) = shared.edit().putBoolean(KEY_ARROW_MOVE, v).apply()

    /** step (in px per frame unit, accelerated by DeX) for arrow cursor moves */
    var arrowStep: Int
        get() = shared.getInt(KEY_ARROW_STEP, 36).coerceIn(8, 120)
        set(v) = shared.edit().putInt(KEY_ARROW_STEP, v.coerceIn(8, 120)).apply()

    /** hold-scroll wheel speed, 1 (slow) .. 10 (fast); default 3 */
    var wheelSpeed: Int
        get() = shared.getInt(KEY_WHEEL_SPEED, 3)
        set(v) = shared.edit().putInt(KEY_WHEEL_SPEED, v.coerceIn(1, 10)).apply()

    /** global requirement: keep the phone in landscape */
    var forceLandscape: Boolean
        get() = shared.getBoolean(KEY_FORCE_LANDSCAPE, true)
        set(v) = shared.edit().putBoolean(KEY_FORCE_LANDSCAPE, v).apply()

    /** the SHARE-button mouse-mode switch (persisted, so a service restart
     *  does not override the user's "off") */
    /** true: left stick = slide/scroll, right stick = pointer (role swap, 通用文档 §4.1) */
    var roleSwap: Boolean
        get() = shared.getBoolean("role_swap", false)
        set(v) = shared.edit().putBoolean("role_swap", v).apply()

    var modeOn: Boolean
        get() = shared.getBoolean(KEY_MODE_ON, true)
        set(v) = shared.edit().putBoolean(KEY_MODE_ON, v).apply()

    fun action(button: String): String {
        val v = shared.getString(btnKey(button), defaultAction(button)) ?: defaultAction(button)
        if (button == "guide") android.util.Log.i("DexPad", "prefs guide key=${btnKey(button)} raw=$v default=${defaultAction(button)}")
        return v
    }

    fun setAction(button: String, action: String) {
        shared.edit().putString(btnKey(button), action).apply()
    }

    /** action fired when the button is held longer than [longMs] (通用 §5.1) */
    fun longAction(button: String): String =
        shared.getString(longKey(button), Action.NONE) ?: Action.NONE

    fun setLongAction(button: String, action: String) {
        shared.edit().putString(longKey(button), action).apply()
    }

    fun longMs(): Long = shared.getInt(KEY_LONG_MS, 500).coerceIn(300, 1000).toLong()

    /**
     * How long A keeps acting as "activate focus" after the last d-pad press.
     * Short by design: the user must be able to click again immediately.
     */
    /** 居中时 raw 单位 → 屏幕像素 的增益（实测约 2.16；指针加速不同会变） */
    val centerGain: Float
        get() = shared.getInt(KEY_CENTER_GAIN, 216).coerceIn(100, 400) / 100f

    fun setCenterGain(v: Int) = shared.edit().putInt(KEY_CENTER_GAIN, v.coerceIn(100, 400)).apply()

    /** 空闲多少秒后隐藏系统指针（0 = 不隐藏） */
    val idleHideSec: Int
        get() = shared.getInt(KEY_IDLE_HIDE_SEC, 8).coerceIn(0, 60)

    fun setIdleHideSec(v: Int) = shared.edit().putInt(KEY_IDLE_HIDE_SEC, v.coerceIn(0, 60)).apply()

    fun focusWindowMs(): Long =
        shared.getInt(KEY_FOCUS_WINDOW_MS, 1200).coerceIn(300, 5000).toLong()

    fun sensX(): Float = shared.getInt(KEY_SENS_X, 100).coerceIn(20, 300) / 100f

    fun sensY(): Float = shared.getInt(KEY_SENS_Y, 100).coerceIn(20, 300) / 100f

    fun edgeSlow(): Int = shared.getInt(KEY_EDGE_SLOW, 40).coerceIn(0, 60)

    fun setSensX(v: Int) { shared.edit().putInt(KEY_SENS_X, v.coerceIn(20, 300)).apply() }

    fun setSensY(v: Int) { shared.edit().putInt(KEY_SENS_Y, v.coerceIn(20, 300)).apply() }

    fun setEdgeSlow(v: Int) { shared.edit().putInt(KEY_EDGE_SLOW, v.coerceIn(0, 60)).apply() }

    fun setFocusWindowMs(v: Int) {
        shared.edit().putInt(KEY_FOCUS_WINDOW_MS, v.coerceIn(300, 5000)).apply()
    }

    // ---- import / export / profiles (通用 §5.4) ----

    /** every stored value (raw map), used as the base of a snapshot */
    private fun putRaw(o: JSONObject, k: String, v: Any?) {
        when (v) {
            is Boolean -> o.put(k, v)
            is Int -> o.put(k, v)
            is Long -> o.put(k, v)
            is Float -> o.put(k, v.toDouble())
            is String -> o.put(k, v)
        }
    }

    /**
     * A complete snapshot: the effective value of every setting (defaults
     * included), so an export can be imported on a fresh install and really
     * restores the configuration.
     */
    fun exportJson(): String {
        val o = JSONObject()
        // scalars (effective values)
        o.put(KEY_ENABLED, enabled)
        o.put(KEY_MODE_ON, modeOn)
        o.put(KEY_SPEED_PHONE, speedPhone)
        o.put(KEY_DEADZONE, deadzone)
        o.put(KEY_SCROLL_DEADZONE, scrollDeadzone)
        o.put(KEY_SCROLL_SPEED, scrollSpeed)
        o.put(KEY_HSWIPE_SPEED, hswipeSpeed)
        o.put(KEY_PRECISION, precisionScale)
        o.put(KEY_INVERT_SCROLL, invertScroll)
        o.put(KEY_VTOUCH, vTouchScroll)
        o.put(KEY_ARROW_MOVE, arrowMovesPointer)
        o.put(KEY_ARROW_STEP, arrowStep)
        o.put(KEY_FORCE_LANDSCAPE, forceLandscape)
        o.put(KEY_WHEEL_SPEED, wheelSpeed)
        o.put(KEY_LONG_MS, longMs().toInt())
        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())
        o.put(KEY_IDLE_HIDE_SEC, idleHideSec)
        o.put(KEY_SENS_X, (sensX() * 100).toInt())
        o.put(KEY_SENS_Y, (sensY() * 100).toInt())
        o.put(KEY_EDGE_SLOW, edgeSlow())
        o.put("role_swap", roleSwap)
        // per-button: single / keyboard combo / double / long
        for (b in BUTTONS) {
            o.put(btnKey(b), action(b))
            o.put(comboKey(b), combo(b))
            o.put(doubleKey(b), doubleAction(b))
            o.put(longKey(b), longAction(b))
        }
        // combslots
        for (i in 0 until MIX_COUNT) {
            o.put(mixKeysKey(i), mixKeys(i).joinToString("+"))
            o.put(mixActionKey(i), mixAction(i))
            o.put(mixValueKey(i), mixValue(i))
        }
        // anything else that was stored by hand (unknown keys survive a round trip)
        for ((k, v) in shared.all) {
            if (!o.has(k)) putRaw(o, k, v)
        }
        o.put("_version", 2)
        return o.toString(2)
    }

    fun importJson(json: String): Boolean {
        return try {
            val o = JSONObject(json)
            val e = shared.edit()
            e.clear()
            for (k in o.keys()) {
                if (k == "_version") continue
                when (val v = o.get(k)) {
                    is Boolean -> e.putBoolean(k, v)
                    is Int -> e.putInt(k, v)
                    is Long -> e.putLong(k, v)
                    is Double -> e.putFloat(k, v.toFloat())
                    is String -> e.putString(k, v)
                }
            }
            e.apply()
            true
        } catch (t: Throwable) {
            false
        }
    }

    fun profiles(): List<String> =
        (shared.getString("profiles", "") ?: "").split(",").filter { it.isNotBlank() }

    fun saveProfile(name: String) {
        val list = profiles().toMutableList()
        if (!list.contains(name)) list.add(name)
        shared.edit()
            .putString("profiles", list.joinToString(","))
            .putString("profile_$name", exportJson())
            .apply()
    }

    fun loadProfile(name: String): Boolean {
        val json = shared.getString("profile_$name", null) ?: return false
        return importJson(json)
    }

    fun deleteProfile(name: String) {
        val list = profiles().filter { it != name }
        shared.edit()
            .putString("profiles", list.joinToString(","))
            .remove("profile_$name")
            .apply()
    }

    /** keyboard shortcut bound to [button] (only used by [Action.KEY_COMBO]) */
    fun combo(button: String): String =
        shared.getString(comboKey(button), defaultCombo(button)) ?: defaultCombo(button)

    fun setCombo(button: String, combo: String) {
        shared.edit().putString(comboKey(button), combo).apply()
    }

    fun doubleKey(button: String) = "double_$button"

    /** action fired when [button] is pressed twice quickly (default: X = switch app) */
    fun doubleAction(button: String): String =
        shared.getString(doubleKey(button), defaultDoubleAction(button)) ?: defaultDoubleAction(button)

    fun setDoubleAction(button: String, action: String) {
        shared.edit().putString(doubleKey(button), action).apply()
    }

    // ------------------------------------------------------------- mix slots

    fun mixKeys(i: Int): List<String> =
        (shared.getString(mixKeysKey(i), defaultMixKeys(i)) ?: "")
            .split("+").filter { it.isNotBlank() }

    fun setMixKeys(i: Int, keys: List<String>) {
        shared.edit().putString(mixKeysKey(i), keys.joinToString("+")).apply()
    }

    fun mixAction(i: Int): String =
        shared.getString(mixActionKey(i), defaultMixAction(i)) ?: defaultMixAction(i)

    fun setMixAction(i: Int, action: String) {
        shared.edit().putString(mixActionKey(i), action).apply()
    }

    fun mixValue(i: Int): String =
        shared.getString(mixValueKey(i), defaultMixValue(i)) ?: defaultMixValue(i)

    fun setMixValue(i: Int, value: String) {
        shared.edit().putString(mixValueKey(i), value).apply()
    }
}
