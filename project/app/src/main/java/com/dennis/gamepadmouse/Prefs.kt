package com.dennis.gamepadmouse

import android.content.Context
import android.content.SharedPreferences

/**
 * All preference keys / defaults / accessors.
 *
 * The key names are identical to the original app ("Gamepad mouse" 2.0.2) so a
 * user can keep their settings and so the analysis documents stay valid.
 */
object Prefs {
    const val FILE = "GamepadMousePrefs"

    // general
    const val MOUSE_ENABLED = "pref_mouse_enabled"                 // boolean, true
    const val TOGGLE_KEYCODE = "pref_toggle_keycode"               // int, 106 (L3)
    const val TOGGLE_ENABLED = "pref_l3_toggle_enabled"            // boolean, true
    const val L3_LONG_PRESS = "pref_l3_long_press_duration"        // int, 0 (=instant), unit 100ms
    const val SWAP_AB = "pref_swap_ab_buttons"                     // boolean, false
    const val HAPTIC = "pref_haptic_feedback"                      // boolean, true
    const val VIBRATION = "pref_vibration_intensity"               // int, 255

    // pointer
    const val MOUSE_SPEED = "pref_mouse_speed"                     // int, 50   (10..200 px/frame)
    const val DEX_SPEED = "pref_dex_speed"                         // int, 35
    const val MOUSE_SIZE = "pref_mouse_size"                       // int, 100  (40..200 px)
    const val SENSITIVITY = "pref_mouse_sensitivity"               // int, 20   (10..30 -> 1.0..3.0)
    const val MOUSE_TIMEOUT = "pref_mouse_timeout"                 // int, 0 = never, else seconds
    const val SCROLL_SPEED = "pref_scroll_speed"                   // int, 100  (10..400)
    const val DEADZONE = "pref_deadzone"                           // int, 15   (1..50 -> 0.01..0.5)

    // cursor look
    const val CURSOR_STYLE = "pref_cursor_style"                   // String, "orange"
    const val CURSOR_COLOR = "pref_cursor_color"                   // String, "#FFA000"

    // DeX
    const val DEX_LOCKSCREEN = "pref_dex_lockscreen_enabled"       // boolean, false
    const val FORCE_MIRRORING = "pref_force_mirroring"             // boolean, false

    // keyboard overlay
    const val KEYBOARD_ENABLED = "pref_keyboard_enabled"           // boolean, true
    const val KB_LANG_EN = "pref_kb_lang_en"                       // boolean, true
    const val KB_LANG_KO = "pref_kb_lang_ko"                       // boolean, true
    const val KB_LANG_ES = "pref_kb_lang_es"                       // boolean, false
    const val KB_NAV_INTERVAL = "pref_kb_nav_interval"             // int, 150
    const val KB_NAV_DELAY = "pref_kb_nav_delay"                   // int, 300
    const val KB_MOVE_SOUND = "pref_kb_move_sound"                 // boolean, false
    const val KB_DEX_WIDTH = "pref_kb_dex_width"                   // int, 50  (%)
    const val KB_DEX_HEIGHT = "pref_kb_dex_height"                 // int, 100 (%)
    const val KB_DEX_POS = "pref_kb_dex_pos"                       // String, "center"

    // root / DeX additions (not in the original app)
    const val ROOT_ENABLED = "pref_root_enabled"                   // boolean, true
    const val START_MOUSE_MODE = "pref_start_mouse_mode"           // boolean, true
    const val ALWAYS_GRAB = "pref_always_grab"                     // boolean, true

    /** boot into mouse mode; a mapped button switches to system mode */
    fun startMouseMode(p: SharedPreferences) = p.getBoolean(START_MOUSE_MODE, true)

    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */
    fun alwaysGrab(p: SharedPreferences) = p.getBoolean(ALWAYS_GRAB, true)
    const val NATIVE_POINTER = "pref_native_pointer"               // boolean, true (needs root)
    const val REPEAT_INTERVAL = "pref_repeat_interval"             // int, 500
    const val HELPER_SOCKET = "pref_helper_socket"                 // String, "" = filesDir/gpm.sock
    const val HIDE_STATUSBAR = "pref_hide_statusbar"                // boolean, true

    // misc
    const val LANGUAGE = "pref_language"                           // "en" | "ko" | "es"
    const val DRAWER_HINT_DONE = "pref_drawer_hint_done"           // boolean, false
    const val INITIAL_SETUP_SHOWN = "pref_initial_setup_shown"     // boolean, false

    /** every Xbox button that can be remapped on its own */
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
    val EXTRA_ACTIONS = listOf("mouse_click", "back", "toggle_mouse", "scroll_up", "scroll_down", "key_combo", "dex_fullscreen")

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

    /** mapping slots: x + (lb|rb|lt|rt|up|down|left|right) combos */
    val SLOTS = listOf("lb", "rb", "lt", "rt", "up", "down", "left", "right")

    fun mappingType(slot: String) = "pref_mapping_x_${slot}_type"
    fun mappingValue(slot: String) = "pref_mapping_x_${slot}_value"
    fun mappingInterval(slot: String) = "pref_mapping_x_${slot}_interval"

    const val PRO_FILE = "GamepadMouseProPrefs"
    const val PRO_IS_PRO = "is_pro_version"

    fun get(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // ---- typed helpers -------------------------------------------------
    fun mouseSpeed(p: SharedPreferences) = p.getInt(MOUSE_SPEED, 50).coerceAtLeast(1)
    fun dexSpeed(p: SharedPreferences) = p.getInt(DEX_SPEED, 35).coerceAtLeast(1)
    fun mouseSize(p: SharedPreferences) = p.getInt(MOUSE_SIZE, 100).coerceAtLeast(20)
    fun sensitivity(p: SharedPreferences) = p.getInt(SENSITIVITY, 20) / 10.0f
    fun scrollSpeed(p: SharedPreferences) = p.getInt(SCROLL_SPEED, 100) / 50.0f
    fun deadzone(p: SharedPreferences) = p.getInt(DEADZONE, 15) / 100.0f
    fun timeoutSeconds(p: SharedPreferences) = p.getInt(MOUSE_TIMEOUT, 0)
    fun toggleKeycode(p: SharedPreferences) = p.getInt(TOGGLE_KEYCODE, 106)
    fun l3LongPress(p: SharedPreferences) = p.getInt(L3_LONG_PRESS, 0)
    fun haptic(p: SharedPreferences) = p.getBoolean(HAPTIC, true)
    fun vibration(p: SharedPreferences) = p.getInt(VIBRATION, 255)

    /** Actions available for the X+button mapping slots (ids as stored). */
    val ACTIONS = listOf(
        "none", "launch_app", "home", "recents", "vol_up", "vol_down", "mute",
        "bright_up", "bright_down", "media_forward", "media_rewind", "screenshot",
        "rotate", "click_location", "click_location_repeat"
    )

    val DEFAULT_MAPPING = linkedMapOf(
        "lb" to "mute",
        "rb" to "none",
        "lt" to "none",
        "rt" to "screenshot",
        "up" to "vol_up",
        "down" to "vol_down",
        "left" to "media_rewind",
        "right" to "media_forward"
    )
}
