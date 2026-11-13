package com.dennis.dexpad

object KeyMap {
    private val table = HashMap<Int, Int>().apply {
        put(0x130, 96)   // BTN_SOUTH  -> BUTTON_A
        put(0x131, 97)   // BTN_EAST   -> BUTTON_B
        put(0x133, 99)   // BTN_NORTH  -> BUTTON_X
        put(0x134, 100)  // BTN_WEST   -> BUTTON_Y
        put(0x136, 102)  // BTN_TL     -> BUTTON_L1
        put(0x137, 103)  // BTN_TR     -> BUTTON_R1
        put(0x138, 104)  // BTN_TL2    -> BUTTON_L2
        put(0x139, 105)  // BTN_TR2    -> BUTTON_R2
        put(0x13a, 109)  // BTN_SELECT -> BUTTON_SELECT
        put(0x13b, 108)  // BTN_START  -> BUTTON_START
        put(0x13c, 110)  // BTN_MODE   -> BUTTON_MODE
        put(0x13d, 106)  // BTN_THUMBL -> BUTTON_THUMBL
        put(0x13e, 107)  // BTN_THUMBR -> BUTTON_THUMBR
        put(0x220, 19)   // BTN_DPAD_UP
        put(0x221, 20)   // BTN_DPAD_DOWN
        put(0x222, 21)   // BTN_DPAD_LEFT
        put(0x223, 22)   // BTN_DPAD_RIGHT
        put(158, 4)      // KEY_BACK
        put(172, 3)      // KEY_HOMEPAGE
        put(139, 82)     // KEY_MENU
        put(116, 26)     // KEY_POWER
        put(167, 130)    // KEY_RECORD -> MEDIA_RECORD (Xbox Share button)
        put(115, 24)     // KEY_VOLUMEUP
        put(114, 25)     // KEY_VOLUMEDOWN
        put(113, 164)    // KEY_MUTE
        put(164, 85)     // KEY_PLAYPAUSE
        put(163, 87)     // KEY_NEXTSONG
        put(165, 88)     // KEY_PREVIOUSSONG
    }

    fun toAndroid(linuxCode: Int): Int? = table[linuxCode]

    /** Android keycode -> button name used by mappings / preferences */
    fun buttonName(androidKeyCode: Int): String? = when (androidKeyCode) {
        96 -> "a"        // BUTTON_A
        97 -> "b"        // BUTTON_B
        99 -> "x"        // BUTTON_X
        100 -> "y"       // BUTTON_Y
        102 -> "lb"
        103 -> "rb"
        104 -> "lt"
        105 -> "rt"
        19 -> "up"
        20 -> "down"
        21 -> "left"
        22 -> "right"
        106 -> "l3"
        107 -> "r3"
        108 -> "start"
        109 -> "select"
        110 -> "guide"
        130 -> "share"   // KEY_RECORD (Xbox Share button) -> MEDIA_RECORD
        else -> null
    }
}
