package com.dennis.dexpad

/** Every mapping target a gamepad button can be assigned to. */
object Action {
    const val NONE = "none"
    const val LEFT = "left_click"
    const val RIGHT = "right_click"
    const val MIDDLE = "middle_click"
    const val WHEEL_UP = "wheel_up"
    const val WHEEL_DOWN = "wheel_down"
    const val TOGGLE = "toggle_mouse"
    const val RECENTS = "recents"
    const val HOME = "home"
    const val BACK = "back"
    const val NOTIFICATIONS = "notifications"
    const val KEY_COMBO = "key_combo"
    const val FORCE_STOP = "force_stop"

    const val MINIMIZE = "minimize_window"      // CMD + -
    const val CLOSE_WINDOW = "close_window"     // ALT + F4
    const val SCREENSHOT = "screenshot_window"  // ALT + PRTSCN

    // touch swipes (finger direction): up/down = pages, left/right = paging
    const val SWIPE_UP = "swipe_up"
    const val SWIPE_DOWN = "swipe_down"
    const val SWIPE_LEFT = "swipe_left"
    const val SWIPE_RIGHT = "swipe_right"

    /** slow variants: short quick flicks (small distance, fast) */
    const val SLOW_SWIPE_UP = "swipe_up_slow"
    const val SLOW_SWIPE_DOWN = "swipe_down_slow"
    const val SLOW_SWIPE_LEFT = "swipe_left_slow"
    const val SLOW_SWIPE_RIGHT = "swipe_right_slow"

    /** one short quick swipe first, then wheel scrolling until release */
    const val SCROLL_SWIPE_UP = "scroll_swipe_up"
    const val SCROLL_SWIPE_DOWN = "scroll_swipe_down"
    const val SCROLL_SWIPE_LEFT = "scroll_swipe_left"
    const val SCROLL_SWIPE_RIGHT = "scroll_swipe_right"

    // wheel scroll: hold = keep scrolling until release (all four directions)
    const val WHEEL_LEFT = "wheel_left"
    const val WHEEL_RIGHT = "wheel_right"
    const val ZOOM_IN = "zoom_in"               // CTRL + PLUS
    const val ZOOM_OUT = "zoom_out"             // CTRL + MINUS

    // media / volume keys
    const val VOLUME_UP = "volume_up"
    const val VOLUME_DOWN = "volume_down"
    const val VOLUME_MUTE = "volume_mute"
    const val PLAY_PAUSE = "play_pause"
    const val NEXT_TRACK = "next_track"
    const val PREV_TRACK = "prev_track"

    /** move the DeX pointer to the centre of the screen */
    const val CENTER_CURSOR = "center_cursor"

    /** simulate the power key: screen off / on */
    const val POWER = "power"

    /** alt+tab: switch to the previous app */
    const val SWITCH_APP = "switch_app"

    /** system arrow keys: move the focus/selection (not the mouse pointer) */
    const val ARROW_UP = "arrow_up"
    const val ARROW_DOWN = "arrow_down"
    const val ARROW_LEFT = "arrow_left"
    const val ARROW_RIGHT = "arrow_right"

    val all = listOf(
        LEFT, RIGHT, MIDDLE, WHEEL_UP, WHEEL_DOWN, WHEEL_LEFT, WHEEL_RIGHT,
        SWIPE_UP, SWIPE_DOWN, SWIPE_LEFT, SWIPE_RIGHT,
        SCROLL_SWIPE_UP, SCROLL_SWIPE_DOWN, SCROLL_SWIPE_LEFT, SCROLL_SWIPE_RIGHT,
        SLOW_SWIPE_UP, SLOW_SWIPE_DOWN, SLOW_SWIPE_LEFT, SLOW_SWIPE_RIGHT, TOGGLE,
        ZOOM_IN, ZOOM_OUT,
        VOLUME_UP, VOLUME_DOWN, VOLUME_MUTE, PLAY_PAUSE, NEXT_TRACK, PREV_TRACK,
        MINIMIZE, CLOSE_WINDOW, SCREENSHOT,
        CENTER_CURSOR, SWITCH_APP, POWER,
        ARROW_UP, ARROW_DOWN, ARROW_LEFT, ARROW_RIGHT,
        RECENTS, HOME, BACK, NOTIFICATIONS, KEY_COMBO, FORCE_STOP, NONE,
    )

    fun label(a: String): String = when (a) {
        LEFT -> "鼠标左键"
        RIGHT -> "鼠标右键"
        MIDDLE -> "鼠标中键"
        WHEEL_UP -> "向上滚动（按住持续）"
        WHEEL_DOWN -> "向下滚动（按住持续）"
        WHEEL_LEFT -> "向左滚动（按住持续）"
        WHEEL_RIGHT -> "向右滚动（按住持续）"
        SWIPE_UP -> "向上滑动"
        SWIPE_DOWN -> "向下滑动"
        SWIPE_LEFT -> "向左滑动"
        SWIPE_RIGHT -> "向右滑动"
        SCROLL_SWIPE_UP -> "向上滑动+滚动"
        SCROLL_SWIPE_DOWN -> "向下滑动+滚动"
        SCROLL_SWIPE_LEFT -> "向左滑动+滚动"
        SCROLL_SWIPE_RIGHT -> "向右滑动+滚动"
        SLOW_SWIPE_UP -> "缓慢向上滑动"
        SLOW_SWIPE_DOWN -> "缓慢向下滑动"
        SLOW_SWIPE_LEFT -> "缓慢向左滑动"
        SLOW_SWIPE_RIGHT -> "缓慢向右滑动"
        TOGGLE -> "切换鼠标模式"
        ZOOM_IN -> "放大（Ctrl + +）"
        ZOOM_OUT -> "缩小（Ctrl + -）"
        VOLUME_UP -> "音量增加"
        VOLUME_DOWN -> "音量减小"
        VOLUME_MUTE -> "静音"
        PLAY_PAUSE -> "播放/暂停"
        NEXT_TRACK -> "下一首"
        PREV_TRACK -> "上一首"
        RECENTS -> "多任务界面"
        HOME -> "主屏幕"
        BACK -> "返回"
        NOTIFICATIONS -> "通知栏"
        KEY_COMBO -> "键盘快捷键"
        MINIMIZE -> "最小化窗口（手机=主屏幕）"
        CLOSE_WINDOW -> "关闭当前应用"
        SCREENSHOT -> "截取窗口截图"
        CENTER_CURSOR -> "光标居中"
        SWITCH_APP -> "切换软件（Alt+Tab）"
        ARROW_UP -> "方向键 ↑"
        ARROW_DOWN -> "方向键 ↓"
        ARROW_LEFT -> "方向键 ←"
        ARROW_RIGHT -> "方向键 →"
        else -> "无"
    }
}
