package com.dennis.dexpad

import android.os.SystemClock
import android.util.Log
import android.view.KeyEvent

/**
 * Executes one-shot actions (buttons and combo slots) through the root helper.
 *
 * The engine only provides the mutable state ([ActionHost]); everything that
 * decides "what a mapped action does" lives here, so new actions are added in a
 * single place together with their phone/DeX variant.
 */
class ActionRouter(private val host: ActionHost) {

    interface ActionHost {
        fun root(): RootInput
        fun prefs(): Prefs
        fun displayState(): DisplayState

        /** display the action goes to (DeX screen or the phone) */
        fun display(): Int

        /** true when there is no DeX screen in use */
        fun isPhone(): Boolean

        /** perform one unified touch swipe; vertical: dir>0 = finger down;
         *  slow = longer duration (fine, gradual scrolling) */
        fun swipe(vertical: Boolean, dir: Int, slow: Boolean = false)

        /** suppress stick movement for a while after an arrow key */
        /** an arrow key was sent (the D-pad is acting as native navigation) */
        fun onArrowKey()

        fun lockArrowsFor(ms: Long)

        /** ignore stick input while the pointer is being centred */
        fun lockCenterFor(ms: Long)

        /** 光标已经被居中：引擎要把自己的位置估计重置到屏幕中心 */
        fun onCentered()

        /** 启动"目标应用"动作里配置的包 */
        fun launchApp(pkg: String)

        /** the pointer must be visible again (e.g. it was hidden while idle) */
        fun onPointerNeeded()

        /** move the pointer to the middle of the display in ONE relative move */
        fun centerPointer()
    }

    fun fire(action: String, comboValue: String) {
        val display = host.display()
        val root = host.root()
        val prefs = host.prefs()
        when (action) {
            Action.RECENTS -> {
                root.pointKey(display, KeyEvent.KEYCODE_APP_SWITCH)
                log("recents on display $display")
            }
            Action.HOME -> {
                root.pointKey(display, KeyEvent.KEYCODE_HOME)
                log("home on display $display")
            }
            Action.BACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_BACK)
                log("back on display $display")
            }
            Action.NOTIFICATIONS -> {
                root.notifyPanel()
                log("notification panel")
            }
            Action.ARROW_UP, Action.ARROW_DOWN, Action.ARROW_LEFT, Action.ARROW_RIGHT -> {
                val code = when (action) {
                    Action.ARROW_UP -> KeyEvent.KEYCODE_DPAD_UP
                    Action.ARROW_DOWN -> KeyEvent.KEYCODE_DPAD_DOWN
                    Action.ARROW_LEFT -> KeyEvent.KEYCODE_DPAD_LEFT
                    else -> KeyEvent.KEYCODE_DPAD_RIGHT
                }
                // The helper normally forwards the physical d-pad to the system
                // (native focus navigation), so this branch runs only when the
                // user mapped a direction to something the app has to inject.
                if (prefs.arrowMovesPointer) {
                    val step = prefs.arrowStep.toFloat()
                    when (action) {
                        Action.ARROW_UP -> root.move(0f, -step)
                        Action.ARROW_DOWN -> root.move(0f, step)
                        Action.ARROW_LEFT -> root.move(-step, 0f)
                        else -> root.move(step, 0f)
                    }
                }
                // 软件在虚拟控制器层之上：方向键不直接注入 keyevent，
                // 而是回写虚拟手柄的 HAT，系统再翻成 DPAD_*（应用/游戏都是原生 d-pad）
                root.hat(
                    when (action) {
                        Action.ARROW_UP -> 1
                        Action.ARROW_DOWN -> 2
                        Action.ARROW_LEFT -> 3
                        else -> 4
                    },
                )
                host.onArrowKey()
                host.lockArrowsFor(300)
                log("arrow key $code on display $display")
            }
            Action.FORCE_STOP -> {
                root.forceStopTop()
                log("force stop foreground package")
            }
            Action.KEY_COMBO -> {
                val codes = KeyCombo.parse(comboValue)
                if (codes.isEmpty()) {
                    Log.w(TAG, "key combo '$comboValue' has no valid keys")
                    return
                }
                // ALT+F4 has no window to close on the phone: close the app.
                if (host.isPhone() && codes.size == 2 &&
                    codes[0] == KeyEvent.KEYCODE_ALT_LEFT && codes[1] == KeyEvent.KEYCODE_F4
                ) {
                    root.closeApp()
                    log("alt+f4 -> close app on phone")
                    return
                }
                root.keyCombo(display, codes)
                log("key combo '$comboValue' -> $codes on display $display")
            }
            Action.MINIMIZE -> {
                root.pointKey(display, KeyEvent.KEYCODE_HOME)
                log("minimize -> home on display $display")
            }
            Action.CLOSE_WINDOW -> {
                root.closeApp()
                log("close app on display $display")
            }
            Action.SCREENSHOT -> {
                root.pointKey(display, KeyEvent.KEYCODE_SYSRQ)
                log("screenshot (SYSRQ) on display $display")
            }
            Action.CENTER_CURSOR -> {
                // 指针可能被「空闲隐藏」销毁了：先恢复，否则居中看不到结果
                host.onPointerNeeded()
                val (w, h) = host.displayState().size(display)
                val rot = host.displayState().rotation(display)
                val gain = host.prefs().centerGain
                host.lockCenterFor(700)
                // 助手侧：有界小步夹角 + 按增益一步到中心（见 gpminput.c cmd_center）
                root.centerCursor(w, h, host.isPhone(), rot, gain)
                host.onCentered()
                log("cursor centered on ${w}x$h (display $display, rot $rot, gain $gain)")
            }
            Action.POWER -> {
                root.powerKey()
                log("power key (screen toggle)")
            }
            Action.SWITCH_APP -> {
                root.switchApp(display)
                log("switch app on display $display")
            }
            Action.SWIPE_UP -> {
                host.swipe(true, -1)
                log("swipe up on display $display")
            }
            Action.SWIPE_DOWN -> {
                host.swipe(true, 1)
                log("swipe down on display $display")
            }
            Action.SWIPE_LEFT -> {
                host.swipe(false, -1)
                log("swipe left on display $display")
            }
            Action.SWIPE_RIGHT -> {
                host.swipe(false, 1)
                log("swipe right on display $display")
            }
            Action.SLOW_SWIPE_UP -> {
                host.swipe(true, -1, slow = true)
                log("slow swipe up on display $display")
            }
            Action.SLOW_SWIPE_DOWN -> {
                host.swipe(true, 1, slow = true)
                log("slow swipe down on display $display")
            }
            Action.SLOW_SWIPE_LEFT -> {
                host.swipe(false, -1, slow = true)
                log("slow swipe left on display $display")
            }
            Action.SLOW_SWIPE_RIGHT -> {
                host.swipe(false, 1, slow = true)
                log("slow swipe right on display $display")
            }
            // zoom = Ctrl + Plus / Ctrl + Minus (browsers and most apps)
            Action.OPEN_APP -> {
                // 每个映射槽自己配的目标包名（空则回退到全局设置）
                val pkg = comboValue.ifBlank { prefs.targetPackage }.trim()
                // 没选应用、或把快捷键文本误存成包名时直接报错，不要盲目 am start
                if (pkg.isBlank() || !pkg.contains('.')) log("open app: 未设置有效的目标应用（$pkg）")
                else {
                    host.launchApp(pkg)
                    log("open app $pkg")
                }
            }
            // 缩放：普通模式由引擎用双指手势（以光标为基准，按住连续）；
            // 只有 d-pad 原生导航模式才用 Ctrl +/- 快捷键
            Action.ZOOM_IN -> combo(display, "zoom in (d-pad mode)", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_PLUS)
            Action.ZOOM_OUT -> combo(display, "zoom out", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_MINUS)
            // media / volume keys; they act on the phone volume stream
            Action.VOLUME_UP -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_UP)
                log("volume up on display $display")
            }
            Action.VOLUME_DOWN -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_DOWN)
                log("volume down on display $display")
            }
            Action.VOLUME_MUTE -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_MUTE)
                log("volume mute on display $display")
            }
            Action.PLAY_PAUSE -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                log("play/pause on display $display")
            }
            Action.NEXT_TRACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_NEXT)
                log("next track on display $display")
            }
            Action.PREV_TRACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                log("previous track on display $display")
            }
        }
    }

    private fun combo(display: Int, what: String, vararg codes: Int) {
        host.root().keyCombo(display, codes.toList())
        log("$what -> ${codes.toList()} on display $display")
    }

    private fun log(msg: String) = Log.i(TAG, msg)

    companion object {
        private const val TAG = "DexPad"
    }
}
