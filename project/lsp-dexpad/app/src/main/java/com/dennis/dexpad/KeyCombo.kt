package com.dennis.dexpad

import android.view.KeyEvent

/**
 * Parses user-typed shortcuts ("ctrl+alt+f", "alt+tab", "win+d", "f5", ...) into
 * Android key codes. The order matters for `input keycombination`, so modifiers
 * stay in front exactly as typed.
 */
object KeyCombo {

    private val named: Map<String, Int> = buildMap {
        put("ctrl", KeyEvent.KEYCODE_CTRL_LEFT)
        put("control", KeyEvent.KEYCODE_CTRL_LEFT)
        put("shift", KeyEvent.KEYCODE_SHIFT_LEFT)
        put("alt", KeyEvent.KEYCODE_ALT_LEFT)
        put("meta", KeyEvent.KEYCODE_META_LEFT)
        put("win", KeyEvent.KEYCODE_META_LEFT)
        put("super", KeyEvent.KEYCODE_META_LEFT)
        put("tab", KeyEvent.KEYCODE_TAB)
        put("space", KeyEvent.KEYCODE_SPACE)
        put("enter", KeyEvent.KEYCODE_ENTER)
        put("return", KeyEvent.KEYCODE_ENTER)
        put("esc", KeyEvent.KEYCODE_ESCAPE)
        put("escape", KeyEvent.KEYCODE_ESCAPE)
        put("backspace", KeyEvent.KEYCODE_DEL)
        put("del", KeyEvent.KEYCODE_FORWARD_DEL)
        put("delete", KeyEvent.KEYCODE_FORWARD_DEL)
        put("insert", KeyEvent.KEYCODE_INSERT)
        put("home", KeyEvent.KEYCODE_MOVE_HOME)
        put("end", KeyEvent.KEYCODE_MOVE_END)
        put("pageup", KeyEvent.KEYCODE_PAGE_UP)
        put("pagedown", KeyEvent.KEYCODE_PAGE_DOWN)
        put("up", KeyEvent.KEYCODE_DPAD_UP)
        put("down", KeyEvent.KEYCODE_DPAD_DOWN)
        put("left", KeyEvent.KEYCODE_DPAD_LEFT)
        put("right", KeyEvent.KEYCODE_DPAD_RIGHT)
        put("play", KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
        put("mute", KeyEvent.KEYCODE_VOLUME_MUTE)
        put("volup", KeyEvent.KEYCODE_VOLUME_UP)
        put("voldown", KeyEvent.KEYCODE_VOLUME_DOWN)
    }

    private val fKey = Regex("f([1-9]|1[0-2])")

    /** Returns the Android key codes in the order the user typed them. */
    fun parse(combo: String): List<Int> {
        val codes = ArrayList<Int>()
        for (raw in combo.split('+', '-', ' ', ',')) {
            val token = raw.trim().lowercase()
            if (token.isEmpty()) continue
            val code = when {
                named.containsKey(token) -> named[token]!!
                token.length == 1 && token[0] in 'a'..'z' ->
                    KeyEvent.KEYCODE_A + (token[0] - 'a')
                token.length == 1 && token[0] in '0'..'9' ->
                    KeyEvent.KEYCODE_0 + (token[0] - '0')
                fKey.matches(token) ->
                    KeyEvent.KEYCODE_F1 + (token.substring(1).toInt() - 1)
                else -> null
            }
            if (code != null) codes.add(code)
        }
        return codes
    }

    /** "ctrl+alt+f" -> "Ctrl + Alt + F" for the list row. */
    fun pretty(combo: String): String =
        combo.split('+', '-', ' ', ',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .joinToString(" + ") { token ->
                if (token.length == 1) token.uppercase()
                else token.replaceFirstChar { it.uppercase() }
            }

    fun isValid(combo: String): Boolean = parse(combo).isNotEmpty()
}
