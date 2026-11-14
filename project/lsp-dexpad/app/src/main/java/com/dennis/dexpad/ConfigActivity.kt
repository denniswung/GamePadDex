package com.dennis.dexpad

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast

/**
 * Settings-style mapping page. It is reachable from the injected row inside
 * Samsung's "Samsung DeX" settings page and
 * from the launcher icon.
 */
class ConfigActivity : Activity() {

    private companion object {
        const val ACCENT = 0xFF4E8CFF.toInt()
        const val TEXT = 0xFFFFFFFF.toInt()
        const val SUB = 0xFF9AA0A6.toInt()
        const val DIVIDER = 0xFF2B2B2B.toInt()
    }

    private val prefs by lazy { Prefs(this) }
    private val handler = Handler(Looper.getMainLooper())

    private lateinit var content: LinearLayout
    private var statusHelper: TextView? = null
    private var statusCaps: TextView? = null
    private var statusDevices: TextView? = null
    private var statusMode: TextView? = null
    private var pointerText: TextView? = null

    private val statusTick = object : Runnable {
        override fun run() {
            refreshStatus()
            handler.postDelayed(this, 500)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        window.setDecorFitsSystemWindows(false)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
        }

        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(8), dp(6), dp(20), dp(6))
        }
        val back = ImageButton(this).apply {
            setImageResource(R.drawable.ic_back)
            background = null
            contentDescription = "返回"
            setOnClickListener { finish() }
        }
        bar.addView(back, LinearLayout.LayoutParams(dp(48), dp(48)))
        bar.addView(TextView(this).apply {
            text = "手柄映射"
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
            setTypeface(typeface, Typeface.BOLD)
        })

        val scroll = ScrollView(this).apply { isFillViewport = true }
        content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(6), dp(20), dp(30))
        }
        scroll.addView(content, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        root.addView(bar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(scroll, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        root.setOnApplyWindowInsetsListener { v, insets ->
            val bars = insets.getInsets(WindowInsets.Type.systemBars())
            v.setPadding(0, bars.top, 0, bars.bottom)
            insets
        }
        setContentView(root)
        rebuild()
    }

    override fun onResume() {
        super.onResume()
        EngineService.ensureRunning(this)
        handler.removeCallbacks(statusTick)
        handler.post(statusTick)
    }

    override fun onPause() {
        handler.removeCallbacks(statusTick)
        super.onPause()
    }

    override fun dispatchGenericMotionEvent(ev: MotionEvent): Boolean {
        if ((ev.source and InputDevice.SOURCE_MOUSE) == InputDevice.SOURCE_MOUSE) {
            val action = ev.actionMasked
            if (action == MotionEvent.ACTION_HOVER_MOVE || action == MotionEvent.ACTION_SCROLL) {
                pointerText?.text = "%.0f, %.0f".format(ev.x, ev.y)
            }
            Log.i("DexPadPointer", "generic action=$action x=${ev.x} y=${ev.y} vs=${ev.getAxisValue(MotionEvent.AXIS_VSCROLL)} hs=${ev.getAxisValue(MotionEvent.AXIS_HSCROLL)}")
        }
        return super.dispatchGenericMotionEvent(ev)
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        Log.i("DexPadPointer", "touch src=${ev.source} action=${ev.actionMasked} x=${ev.x} y=${ev.y} buttons=${ev.buttonState}")
        if ((ev.source and InputDevice.SOURCE_MOUSE) == InputDevice.SOURCE_MOUSE &&
            ev.actionMasked == MotionEvent.ACTION_DOWN
        ) {
            pointerText?.text = "%.0f, %.0f".format(ev.x, ev.y)
        }
        return super.dispatchTouchEvent(ev)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        Log.i("DexPadKeys", "key code=${event.keyCode} meta=${event.metaState} action=${event.action} repeat=${event.repeatCount}")
        return super.dispatchKeyEvent(event)
    }

    // ------------------------------------------------------------------ views

    private fun rebuild() {
        content.removeAllViews()
        buildGeneral()
        buildStatus()
        buildPointer()
        buildWheel()
        buildMapping()
        buildData()
        buildFooter()
    }

    private fun buildGeneral() {
        content.addView(card(
            switchRow(
                "启用手柄映射",
                "关闭后手柄完全交还给系统",
                prefs.enabled,
            ) { v ->
                prefs.enabled = v
                EngineService.ensureRunning(this)
            },
        ))
    }

    private fun buildStatus() {
        statusHelper = valueView()
        statusDevices = valueView()
        statusMode = valueView()
        pointerText = valueView()
        pointerText!!.text = "—"
        statusCaps = valueView()
        statusCaps!!.text = "—"
        content.addView(card(
            infoRow("Root 助手", statusHelper!!),
            infoRow("手柄", statusDevices!!),
            infoRow("鼠标模式", statusMode!!),
            infoRow("指针位置", pointerText!!),
            infoRow("链路自检", statusCaps!!),
        ))
        refreshStatus()
    }

    /** "打开目标应用"动作的目标包名选择器 */
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
        val items = apps.map { "${it.first}\n${it.second}" }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("选择目标应用")
            .setItems(items) { _, i ->
                prefs.targetPackage = apps[i].second
                rebuild()
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun buildPointer() {
        content.addView(card(
            sliderRow("手机指针速度", 5, 100, prefs.speedPhone, " px/帧") { v -> prefs.speedPhone = v },
            sliderRow("摇杆死区", 0, 40, prefs.deadzone / 10, "%") { v -> prefs.deadzone = v * 10 },
            sliderRow("精准移动（X+左摇杆）", 5, 50, prefs.precisionScale, "% 速度") { v -> prefs.precisionScale = v },
            sliderRow("水平灵敏度 X", 20, 300, (prefs.sensX() * 100).toInt(), "%") { v -> prefs.setSensX(v) },
            sliderRow("垂直灵敏度 Y", 20, 300, (prefs.sensY() * 100).toInt(), "%") { v -> prefs.setSensY(v) },
            sliderRow("边缘减速", 0, 60, prefs.edgeSlow(), "%") { v -> prefs.setEdgeSlow(v) },
            sliderRow("居中增益", 100, 400, (prefs.centerGain * 100).toInt(), " %") { v -> prefs.setCenterGain(v) },
            sliderRow("空闲隐藏指针", 0, 30, prefs.idleHideSec, " s") { v -> prefs.setIdleHideSec(v) },
            sliderRow("方向键焦点窗口", 3, 50, (prefs.focusWindowMs() / 100).toInt(), "00 ms") { v ->
                prefs.setFocusWindowMs(v * 100)
            },
            switchRow(
                "方向键同时移动光标",
                "按方向键时光标也朝该方向走一步",
                prefs.arrowMovesPointer,
            ) { v -> prefs.arrowMovesPointer = v },
            sliderRow("方向键移动步长", 8, 120, prefs.arrowStep, " px") { v -> prefs.arrowStep = v },
        ))
    }

    private fun buildWheel() {
        content.addView(card(
            sliderRow("滚动速度", 1, 10, prefs.scrollSpeed, "") { v -> prefs.scrollSpeed = v },
            sliderRow("滚轮速度（按住持续滚动）", 1, 10, prefs.wheelSpeed, "") { v -> prefs.wheelSpeed = v },
            sliderRow("滚动死区", 5, 60, prefs.scrollDeadzone / 10, "%") { v -> prefs.scrollDeadzone = v * 10 },
            sliderRow("水平滑动速度", 1, 10, prefs.hswipeSpeed, "") { v -> prefs.hswipeSpeed = v },
            switchRow(
                "上下滑动用触摸拖动",
                "更顺滑，适合视频/卡片流（关掉则用滚轮）",
                prefs.vTouchScroll,
            ) { v -> prefs.vTouchScroll = v },
            switchRow("反向滚动", null, prefs.invertScroll) { v -> prefs.invertScroll = v },
        ))
    }

    private fun buildMapping() {
        val rows = ArrayList<View>()
        for (b in Prefs.BUTTONS) rows.add(mappingRow(b))
        content.addView(card(*rows.toTypedArray()))
    }

    private fun buildData() {
        content.addView(card(
            actionButton("导出配置…") { exportConfig() },
            divider(),
            actionButton("导入配置…") { importConfig() },
            divider(),
            actionButton("保存为 Profile…") { saveProfileDialog() },
            divider(),
            actionButton("加载 Profile…") { loadProfileDialog() },
            divider(),
            actionButton("手柄测试页") {
                startActivity(android.content.Intent(this, GamepadTestActivity::class.java))
            },
        ))
    }

    private fun exportConfig() {
        try {
            val f = java.io.File(filesDir, "dexpad-config.json")
            f.writeText(prefs.exportJson())
            Toast.makeText(this, "已导出：${f.absolutePath}", Toast.LENGTH_LONG).show()
        } catch (t: Throwable) {
            Toast.makeText(this, "导出失败：${t.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun importConfig() {
        try {
            val f = java.io.File(filesDir, "dexpad-config.json")
            if (!f.exists()) {
                Toast.makeText(this, "未找到 ${f.absolutePath}", Toast.LENGTH_SHORT).show()
                return
            }
            val ok = prefs.importJson(f.readText())
            Toast.makeText(this, if (ok) "导入成功" else "导入失败（JSON 无效）", Toast.LENGTH_SHORT).show()
            if (ok) rebuild()
        } catch (t: Throwable) {
            Toast.makeText(this, "导入失败：${t.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun saveProfileDialog() {
        // pre-fill a free name so saving is one tap (the user can still edit it)
        val names = prefs.profiles()
        var idx = names.size + 1
        while (names.contains("profile$idx")) idx++
        promptText("保存 Profile", "profile$idx") { name ->
            if (name.isNotBlank()) {
                prefs.saveProfile(name)
                Toast.makeText(this, "已保存 Profile：$name", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun loadProfileDialog() {
        val names = prefs.profiles()
        if (names.isEmpty()) {
            Toast.makeText(this, "还没有 Profile", Toast.LENGTH_SHORT).show()
            return
        }
        AlertDialog.Builder(this)
            .setTitle("加载 Profile")
            .setItems(names.toTypedArray()) { _, i ->
                if (prefs.loadProfile(names[i])) {
                    Toast.makeText(this, "已加载：${names[i]}", Toast.LENGTH_SHORT).show()
                    rebuild()
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun promptText(title: String, initial: String, onSave: (String) -> Unit) {
        val input = android.widget.EditText(this).apply {
            setText(initial)
            setSingleLine()
        }
        AlertDialog.Builder(this)
            .setTitle(title)
            .setView(input)
            .setPositiveButton("确定") { _, _ -> onSave(input.text.toString().trim()) }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun actionButton(title: String, onClick: () -> Unit): View {
        return TextView(this).apply {
            text = title
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(dp(18), dp(14), dp(18), dp(14))
            isClickable = true
            setOnClickListener { onClick() }
        }
    }

    private fun buildFooter() {
        content.addView(TextView(this).apply {
            text = "提示：映射只在鼠标模式开启时生效。默认按手柄 SHARE 键在「鼠标模式」和「交还手柄」之间切换" +
                "（L3 也可以另外分配成切换）。\n" +
                "组合键在按键详情页里设置：点按上面的按键行，可设置「单击动作」以及「该键 + 其它键」的所有组合。" +
                "\n" +
                "Root 助手必须运行：本机 KernelSU 为 late-load 模式，模块开机脚本不会执行，" +
                "重启后请用 adb 执行一次「sh /data/local/tmp/dexpad_start.sh」。"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setLineSpacing(dp(3).toFloat(), 1f)
        })
    }

    private fun card(vararg rows: View): View {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = getDrawable(R.drawable.bg_card)
        }
        rows.forEachIndexed { i, row ->
            if (i > 0) card.addView(divider())
            card.addView(row)
        }
        val lp = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        lp.bottomMargin = dp(14)
        card.layoutParams = lp
        return card
    }

    private fun divider() = View(this).apply {
        setBackgroundColor(DIVIDER)
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 1,
        ).also { it.leftMargin = dp(18); it.rightMargin = dp(18) }
    }

    private fun switchRow(title: String, summary: String?, checked: Boolean, onChange: (Boolean) -> Unit): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
        }
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(TextView(this).apply {
            text = title
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        })
        if (summary != null) {
            texts.addView(TextView(this).apply {
                text = summary
                setTextColor(SUB)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            })
        }
        row.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        val sw = Switch(this).apply {
            isChecked = checked
            setOnCheckedChangeListener { _, b -> onChange(b) }
        }
        row.addView(sw)
        return row
    }

    private fun sliderRow(title: String, min: Int, max: Int, value: Int, unit: String, onChange: (Int) -> Unit): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(4))
        }
        val head = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        head.addView(TextView(this).apply {
            text = title
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        val valueView = TextView(this).apply {
            text = "$value$unit"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        }
        head.addView(valueView)
        row.addView(head)

        val bar = SeekBar(this).apply {
            this.max = max - min
            progress = (value - min).coerceIn(0, max - min)
            progressTintList = ColorStateList.valueOf(ACCENT)
            thumbTintList = ColorStateList.valueOf(ACCENT)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    val v = progress + min
                    valueView.text = "$v$unit"
                    onChange(v)
                }

                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        row.addView(bar)
        return row
    }

    private fun infoRow(title: String, value: TextView): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
        }
        row.addView(TextView(this).apply {
            text = title
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(value)
        return row
    }

    private fun valueView() = TextView(this).apply {
        setTextColor(SUB)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        text = "—"
    }

    private fun mappingRow(button: String): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
            isClickable = true
        }
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(TextView(this).apply {
            text = Prefs.buttonLabel(button)
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        })
        texts.addView(TextView(this).apply {
            text = summaryOf(button)
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        })
        row.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(TextView(this).apply {
            text = "›"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
        })
        row.setOnClickListener {
            startActivity(
                android.content.Intent(this, ButtonDetailActivity::class.java)
                    .putExtra("button", button),
            )
        }
        return row
    }

    private fun summaryOf(button: String): String {
        val action = prefs.action(button)
        val single = if (action == Action.KEY_COMBO) {
            "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
        } else {
            Action.label(action)
        }
        val dbl = prefs.doubleAction(button)
        return if (dbl == Action.NONE) single
        else "$single · 双击：${Action.label(dbl)}"
    }

    private fun chooseAction(button: String) {
        pickAction("${Prefs.buttonLabel(button)} → 映射动作") { picked ->
            prefs.setAction(button, picked)
            if (picked == Action.KEY_COMBO) {
                editCombo("${Prefs.buttonLabel(button)} 的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
            } else {
                rebuild()
            }
        }
    }

    private fun pickAction(title: String, onPicked: (String) -> Unit) {
        val labels = Action.all.map { Action.label(it) }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle(title)
            .setItems(labels) { _, which -> onPicked(Action.all[which]) }
            .setNegativeButton("取消") { _, _ -> rebuild() }
            .show()
    }

    /** small editor for a keyboard shortcut (button or mix slot) */
    private fun editCombo(title: String, current: String, onSave: (String) -> Unit) {
        val input = android.widget.EditText(this).apply {
            setText(current)
            setSelectAllOnFocus(true)
            setHint("例如 ctrl+alt+f、alt+tab、win+d、f5")
            setSingleLine(true)
        }
        val box = android.widget.FrameLayout(this)
        val lp = android.widget.FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        lp.leftMargin = dp(24)
        lp.rightMargin = dp(24)
        lp.topMargin = dp(8)
        box.addView(input, lp)
        AlertDialog.Builder(this)
            .setTitle(title)
            .setView(box)
            .setPositiveButton("保存") { _, _ ->
                val combo = input.text.toString().trim().lowercase()
                if (combo.isNotEmpty() && KeyCombo.parse(combo).isEmpty()) {
                    android.widget.Toast.makeText(this, "无法识别的快捷键：$combo", android.widget.Toast.LENGTH_SHORT).show()
                } else if (combo.isNotEmpty()) {
                    onSave(combo)
                }
                rebuild()
            }
            .setNegativeButton("取消") { _, _ -> rebuild() }
            .show()
    }

    private fun refreshStatus() {
        statusHelper?.text = if (EngineState.connected) "已连接" else "未连接 · 需启动助手"
        statusDevices?.text = if (EngineState.devices.isEmpty()) "未检测到" else EngineState.devices.joinToString("，")
        statusMode?.text = if (EngineState.modeOn) "开启" else "关闭"
        val caps = EngineState.caps
        statusCaps?.text = if (caps.isEmpty()) {
            "未检测（助手运行后自动检测）"
        } else {
            val bad = caps.filter { it.value == 0 }.keys
            if (bad.isEmpty()) "全部通过（${caps.size} 项）" else "缺失：" + bad.joinToString("，")
        }
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
}
