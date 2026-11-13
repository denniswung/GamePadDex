package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src

/**
 * 四、按键测试页（接收端）。
 *
 * 重要前提（也是本页最容易被误解的地方）：
 * 被测映射程序用 EVIOCGRAB 独占手柄，手柄的 A/B/X/Y 不会到达本 App。
 * 本页看到的是**映射后的注入键流**（Home/Back/音量/静音/方向键，以及 Ctrl+Plus 这类组合）。
 * 因此「A 是否映射成左键」不能在这里直接看到，而是用「监听」按钮：
 * 点某个按钮 → 进入 3 秒监听窗 → 你在手柄上按那个键 → App 比对**随后出现的动作**是否符合预期。
 *
 * 页面包含：
 * 1. 最近按键（键名 / keyCode / 按下-释放 / 按住时长）；
 * 2. 单击 / 双击候选 / 长按 判定与窗口倒计时；
 * 3. 当前按下的键集合，以及「发起键 → 参与键」识别（对 Ctrl+Plus 这类注入组合有效）；
 * 4. X+A 与 A+X 两行监听，人工核对是否等价/独立；
 * 5. 可自定义的「预期动作」比对，绿=符合、红=不符合。
 */
class KeyTestActivity : ProbeActivity() {

    private lateinit var lastKeyView: TextView
    private lateinit var judgeView: TextView
    private lateinit var pressedView: TextView
    private lateinit var comboView: TextView
    private lateinit var expectView: TextView

    private val pressed = LinkedHashSet<String>()
    private val pressOrder = ArrayList<String>()
    private var lastDownAt = 0L
    private var lastUpAt = 0L
    private var lastHoldMs = 0L
    private var lastLabel = "-"
    private var doubleCandidate = false
    private var longFired = false
    private var pendingDoubleLabel = ""

    // 监听窗
    private var armedLabel = ""
    private var armedExpect = ""
    private var armedUntil = 0L
    private var armedResult = ""

    private val handler = Handler(Looper.getMainLooper())
    private val tick = object : Runnable {
        override fun run() {
            refreshJudge()
            refreshArmWindow()
            handler.postDelayed(this, 60)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        CheckRegistry.define("KEY.RECEIVE", "按键", "收到注入按键")
        CheckRegistry.define("KEY.LONG", "按键", "长按可识别")
        CheckRegistry.define("KEY.COMBO", "按键", "组合以发起键命名")
        CheckRegistry.define("KEY.EQUIV", "按键", "X+A 与 A+X 等价/独立可核对")
        super.onCreate(savedInstanceState)
    }

    override fun buildContent(): View {
        val col = page("按键测试（接收端）", "手柄按键被映射程序独占，这里看到的是映射后的注入键流")

        lastKeyView = mono("最近按键 -", 12f, 0xFF4FC3F7.toInt())
        judgeView = mono("判定 -", 12f, 0xFFFFD740.toInt())
        pressedView = mono("按下集合 -", 12f)
        comboView = mono("组合 -", 12f)
        col.addView(card(lastKeyView, judgeView, pressedView, comboView))

        expectView = tv("监听结果 -", 12f, 0xFFB0BEC5.toInt())
        col.addView(card(
            tv("② 预期动作比对：点「监听」后 3 秒内按手柄上的对应键", 12f, Color.WHITE),
            expectRow("A", "左键"),
            expectRow("B", "返回"),
            expectRow("Y", "Home"),
            expectRow("R3", "静音"),
            expectRow("X", "无动作（不应有动作）"),
            expectRow("X+A", "（填写预期，例如 无动作 / 多任务）"),
            expectRow("A+X", "（同上，用于核对是否与 X+A 等价）"),
            expectView,
        ))

        col.addView(card(
            tv("③ 自定义预期", 12f, Color.WHITE),
            buildCustomRow(),
        ))

        val note = tv(
            "说明：本页只做「接收端」验证。手柄原始按键被 EVIOCGRAB 独占，App 无法直接读取；\n" +
                "若需要看「手柄按键 → 动作」的原始语义，请对照映射程序的日志（tag DexPad）。",
            11f,
            0xFF7C8B99.toInt(),
        )
        col.addView(card(note))
        return scroll(col)
    }

    private fun buildCustomRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val label = EditText(this).apply { hint = "触发（如 X+A）"; setText("") }
        val expect = EditText(this).apply { hint = "预期动作（如 多任务）"; setText("") }
        row.addView(label, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(expect, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(button("监听") {
            arm(label.text.toString().ifBlank { "自定义" }, expect.text.toString())
        })
        return row
    }

    private val expectRows = ArrayList<Pair<LinearLayout, TextView>>()

    private fun expectRow(label: String, defaultExpect: String): View {
        val line = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val title = tv("%-4s → %s".format(label, defaultExpect), 11f, 0xFFCFD8DC.toInt())
        val state = tv("未测", 11f, 0xFF7C8B99.toInt())
        line.addView(title, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        line.addView(state)
        line.addView(button("监听") { arm(label, defaultExpect) })
        expectRows.add(line to state)
        return line
    }

    private fun arm(label: String, expect: String) {
        armedLabel = label
        armedExpect = expect
        armedUntil = SystemClock.elapsedRealtime() + 3000
        armedResult = "监听中：$label → 期望「$expect」…"
        renderArm()
    }

    private fun renderArm() {
        val text = if (armedUntil > 0) armedResult else "监听结果 -"
        expectView.text = text
        val rowLabel = armedLabel
        for ((line, state) in expectRows) {
            val title = (line.getChildAt(0) as TextView).text.toString()
            if (title.startsWith(rowLabel.padEnd(4))) {
                state.text = if (armedUntil > 0) "监听中" else if (armedResult.startsWith("✔")) "通过" else "失败"
                state.setTextColor(
                    if (armedUntil > 0) 0xFFFFD740.toInt()
                    else if (armedResult.startsWith("✔")) 0xFF69F0AE.toInt() else 0xFFFF5252.toInt(),
                )
            }
        }
    }

    private fun refreshArmWindow() {
        if (armedUntil == 0L) return
        val left = armedUntil - SystemClock.elapsedRealtime()
        if (left <= 0) {
            armedUntil = 0
            if (!armedResult.startsWith("✔") && !armedResult.startsWith("✘")) {
                armedResult = "✘ 超时：3 秒内没收到动作（$armedLabel）"
                CheckRegistry.fail("KEY.EQUIV", armedResult)
            }
            renderArm()
        } else {
            if (!armedResult.startsWith("✔") && !armedResult.startsWith("✘")) {
                armedResult = "监听中：$armedLabel → 「$armedExpect」 剩余 ${left}ms"
                renderArm()
            }
        }
    }

    // ---------------------------------------------------------------- 判定显示

    private fun refreshJudge() {
        val now = SystemClock.elapsedRealtime()
        val sb = StringBuilder()
        sb.append("最近按键 ").append(lastLabel).append('\n')
        if (lastDownAt > 0) {
            sb.append("  按下于 ").append(ProbeEvent.timeText(System.currentTimeMillis() - (now - lastDownAt))).append('\n')
        }
        sb.append("  按住时长 ").append(lastHoldMs).append("ms\n")
        judgeView.text = sb.toString()

        val j = StringBuilder()
        val sinceUp = now - lastUpAt
        val sinceDown = now - lastDownAt
        if (doubleCandidate && sinceUp < 320 && lastUpAt > 0) {
            j.append("疑似双击（窗口剩余 ${320 - sinceUp}ms）\n")
        }
        if (lastDownAt > 0 && lastUpAt < lastDownAt && sinceDown in 0..5000) {
            j.append("按住中 ").append(sinceDown).append("ms")
            j.append(if (sinceDown >= 500) "（已达长按阈值）" else "（长按阈值 500ms，剩余 ${500 - sinceDown}ms）")
            j.append('\n')
        }
        if (longFired) j.append("长按已触发\n")
        if (j.isEmpty()) j.append("判定：等待按键\n")
        if (pendingDoubleLabel.isNotEmpty()) j.append("上次双击候选：").append(pendingDoubleLabel).append('\n')
        // 这一行同时给 judgeView 用（合并显示）
        judgeView.text = sb.toString() + j.toString()
    }

    // ---------------------------------------------------------------- 事件

    override fun onProbeEvent(e: ProbeEvent) {
        when {
            e.src == Src.KEY && e.kind == "key-down" -> onKeyDownEvent(e)
            e.src == Src.KEY && e.kind == "key-up" -> onKeyUpEvent(e)
            else -> onActionEvent(e)
        }
    }

    private fun onKeyDownEvent(e: ProbeEvent) {
        val name = e.extra["name"] ?: e.detail.substringBefore('(')
        lastLabel = name
        val now = SystemClock.elapsedRealtime()
        val gap = if (lastUpAt > 0) now - lastUpAt else Long.MAX_VALUE
        doubleCandidate = gap < 320
        if (doubleCandidate) pendingDoubleLabel = name
        lastDownAt = now
        lastHoldMs = 0
        longFired = false

        pressed.add(name)
        if (!pressOrder.contains(name)) pressOrder.add(name)
        pressedView.text = "按下集合：${pressed.joinToString(", ")}"

        if (pressOrder.size >= 2) {
            val leader = pressOrder.first()
            val parts = pressOrder.drop(1)
            comboView.text = "组合识别：发起键 $leader → 参与键 ${parts.joinToString("+")}"
            CheckRegistry.pass("KEY.COMBO", "$leader → ${parts.joinToString("+")}")
        }
        CheckRegistry.pass("KEY.RECEIVE", name)

        // 长按检测
        handler.postDelayed({
            if (lastDownAt == now && SystemClock.elapsedRealtime() - now >= 480) {
                longFired = true
                lastHoldMs = SystemClock.elapsedRealtime() - now
                CheckRegistry.pass("KEY.LONG", "$name 按住 >=500ms")
            }
        }, 500)
        classifyForArm(e)
    }

    private fun onKeyUpEvent(e: ProbeEvent) {
        val name = e.extra["name"] ?: e.detail.substringBefore('(')
        lastUpAt = SystemClock.elapsedRealtime()
        lastHoldMs = e.extra["held"]?.toLongOrNull() ?: 0L
        pressed.remove(name)
        pressedView.text = if (pressed.isEmpty()) "按下集合：（空）" else "按下集合：${pressed.joinToString(", ")}"
        if (pressed.isEmpty()) pressOrder.clear()
    }

    private fun onActionEvent(e: ProbeEvent) {
        val action = describe(e) ?: return
        if (armedUntil > 0) {
            // 监听窗内出现的第一个动作，就是判定依据
            armedUntil = 0
            val ok = armedExpect.isBlank() || action.contains(armedExpect) ||
                (armedExpect.contains("无动作") && action == "无动作")
            armedResult = if (ok) {
                CheckRegistry.pass("KEY.EQUIV", "$armedLabel → $action")
                "✔ $armedLabel 触发「$action」，符合预期「$armedExpect」"
            } else {
                CheckRegistry.fail("KEY.EQUIV", "$armedLabel 触发「$action」，期望「$armedExpect」")
                "✘ $armedLabel 触发「$action」，期望「$armedExpect」"
            }
            renderArm()
        }
    }

    private fun classifyForArm(e: ProbeEvent) {
        // 按键本身也可能是“动作”（如 R3→静音 是注入 KEYCODE_MUTE）
        val action = describe(e) ?: return
        if (armedUntil > 0 && action != "按键 ${e.extra["name"]}") {
            armedUntil = 0
            val ok = armedExpect.isBlank() || action.contains(armedExpect)
            armedResult = if (ok) "✔ $armedLabel → $action" else "✘ $armedLabel → $action（期望 $armedExpect）"
            if (ok) CheckRegistry.pass("KEY.EQUIV", armedResult) else CheckRegistry.fail("KEY.EQUIV", armedResult)
            renderArm()
        }
    }

    /** 把注入事件翻译成人类可读的动作名（用于预期比对） */
    private fun describe(e: ProbeEvent): String? = when {
        e.src == Src.MOUSE && e.kind == "click-down" -> "左键"
        e.src == Src.MOUSE && e.kind == "hover" -> null
        e.src == Src.WHEEL -> "滚轮"
        e.src == Src.TOUCH && e.kind == "touch-down" -> "触摸"
        e.src == Src.KEY && e.kind == "key-down" -> {
            when (e.extra["code"]?.toIntOrNull()) {
                KeyEvent.KEYCODE_BACK -> "返回"
                KeyEvent.KEYCODE_HOME -> "Home"
                KeyEvent.KEYCODE_APP_SWITCH -> "多任务"
                KeyEvent.KEYCODE_MUTE -> "静音"
                KeyEvent.KEYCODE_VOLUME_UP -> "音量+"
                KeyEvent.KEYCODE_VOLUME_DOWN -> "音量-"
                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> "播放/暂停"
                KeyEvent.KEYCODE_MEDIA_NEXT -> "下一首"
                KeyEvent.KEYCODE_MEDIA_PREVIOUS -> "上一首"
                KeyEvent.KEYCODE_DPAD_UP -> "方向键"
                KeyEvent.KEYCODE_DPAD_DOWN -> "方向键"
                KeyEvent.KEYCODE_DPAD_LEFT -> "方向键"
                KeyEvent.KEYCODE_DPAD_RIGHT -> "方向键"
                KeyEvent.KEYCODE_DPAD_CENTER -> "激活焦点"
                KeyEvent.KEYCODE_CTRL_LEFT -> "按键 Ctrl"
                KeyEvent.KEYCODE_PLUS -> "按键 +"
                KeyEvent.KEYCODE_MINUS -> "按键 -"
                else -> "按键 ${e.extra["name"]}"
            }
        }
        else -> null
    }

    override fun onResume() {
        super.onResume()
        handler.post(tick)
    }

    override fun onPause() {
        handler.removeCallbacks(tick)
        super.onPause()
    }
}
