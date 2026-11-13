package com.dennis.dexpad

import android.app.Activity
import android.app.AlertDialog
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

/**
 * Per-button editor: the single action of one button plus every multi-button
 * combo that involves it. Reached by tapping a row on the mapping page
 * (the old behaviour opened the action picker directly; combos were buried in
 * a separate card with fixed slots).
 */
class ButtonDetailActivity : Activity() {

    private companion object {
        const val ACCENT = 0xFF4E8CFF.toInt()
        const val TEXT = 0xFFFFFFFF.toInt()
        const val SUB = 0xFF9AA0A6.toInt()
        const val DIVIDER = 0xFF2B2B2B.toInt()
    }

    private val prefs by lazy { Prefs(this) }
    private lateinit var button: String
    private lateinit var content: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        button = intent.getStringExtra("button") ?: Prefs.BUTTONS.first()
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
        bar.addView(ImageButton(this).apply {
            setImageResource(R.drawable.ic_back)
            background = null
            contentDescription = "返回"
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(dp(48), dp(48)))
        bar.addView(TextView(this).apply {
            text = "${Prefs.buttonLabel(button)} 键"
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

    private fun rebuild() {
        content.removeAllViews()
        content.addView(card(
            header("单击动作", "单独按 ${Prefs.buttonLabel(button)} 时触发"),
            actionRow,
            divider(),
            header("双击动作", "连续按两下 ${Prefs.buttonLabel(button)}（320 ms 内）时触发"),
            actionRow("双击动作", doubleSummary()) { pickDouble() },
            divider(),
            header("长按动作", "按住 ${Prefs.buttonLabel(button)} 超过 ${prefs.longMs()} ms 时触发（会取消单击/双击）"),
            actionRow("长按动作", longSummary()) { pickLong() },
        ))
        val combos = (0 until Prefs.MIX_COUNT).filter { prefs.mixKeys(it).contains(button) }
        val rows = ArrayList<View>()
        rows.add(header("组合键", "同时按住 ${Prefs.buttonLabel(button)} + 其它按键时触发"))
        if (combos.isEmpty()) {
            rows.add(info("还没有和 ${Prefs.buttonLabel(button)} 的组合，点下面添加"))
        } else {
            combos.forEachIndexed { idx, slot ->
                if (idx > 0) rows.add(divider())
                rows.add(comboRow(slot))
            }
        }
        rows.add(divider())
        rows.add(actionRow("添加组合…", "") {
            addCombo()
        })
        content.addView(card(*rows.toTypedArray()))
    }

    /** the single action of this button */
    private val actionRow: View
        get() = actionRow("当前动作", summaryOf(button)) {
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

    private fun doubleSummary(): String {
        val d = prefs.doubleAction(button)
        return when (d) {
            Action.NONE -> "无（关闭）"
            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            else -> Action.label(d)
        }
    }

    private fun longSummary(): String {
        val d = prefs.longAction(button)
        return when (d) {
            Action.NONE -> "无（关闭）"
            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            else -> Action.label(d)
        }
    }

    private fun pickLong() {
        pickAction("${Prefs.buttonLabel(button)} → 长按动作") { picked ->
            prefs.setLongAction(button, picked)
            if (picked == Action.KEY_COMBO) {
                editCombo("${Prefs.buttonLabel(button)} 长按的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
            } else {
                rebuild()
            }
        }
    }

    private fun pickDouble() {
        pickAction("${Prefs.buttonLabel(button)} → 双击动作") { picked ->
            prefs.setDoubleAction(button, picked)
            if (picked == Action.KEY_COMBO) {
                editCombo("${Prefs.buttonLabel(button)} 双击的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
            } else {
                rebuild()
            }
        }
    }

    private fun actionRow(label: String, value: String, onClick: () -> Unit): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
            isClickable = true
            setOnClickListener { onClick() }
        }
        row.addView(TextView(this).apply {
            text = label
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        if (value.isNotEmpty()) {
            row.addView(TextView(this).apply {
                text = value
                setTextColor(SUB)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            })
        }
        row.addView(TextView(this).apply {
            text = "›"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(dp(8), 0, 0, 0)
        })
        return row
    }

    private fun comboRow(slot: Int): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(18), dp(12))
            isClickable = true
            setOnLongClickListener {
                confirmDelete(slot)
                true
            }
        }
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(TextView(this).apply {
            text = prefs.mixKeys(slot).joinToString(" + ") { Prefs.buttonLabel(it) }
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        })
        texts.addView(TextView(this).apply {
            text = mixActionLabel(slot) + " · 长按删除"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        })
        row.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(TextView(this).apply {
            text = "›"
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
        })
        row.setOnClickListener { editMixKeys(slot) }
        return row
    }

    private fun confirmDelete(slot: Int) {
        AlertDialog.Builder(this)
            .setTitle("删除组合")
            .setMessage(prefs.mixKeys(slot).joinToString(" + ") { Prefs.buttonLabel(it) })
            .setPositiveButton("删除") { _, _ ->
                prefs.setMixKeys(slot, emptyList())
                prefs.setMixAction(slot, Action.NONE)
                rebuild()
            }
            .setNegativeButton("取消", null)
            .show()
    }

    /** create a combo that starts with this button */
    private fun addCombo() {
        val partners = Prefs.BUTTONS.filter { it != button }
        val labels = partners.map { Prefs.buttonLabel(it) }.toTypedArray()
        val selected = BooleanArray(partners.size)
        AlertDialog.Builder(this)
            .setTitle("${Prefs.buttonLabel(button)} + 选择其它按键")
            .setMultiChoiceItems(labels, selected) { _, which, checked -> selected[which] = checked }
            .setPositiveButton("下一步") { _, _ ->
                val extra = partners.filterIndexed { idx, _ -> selected[idx] }
                if (extra.isEmpty()) {
                    toast("至少再选 1 个按键")
                    return@setPositiveButton
                }
                val slot = (0 until Prefs.MIX_COUNT).firstOrNull { prefs.mixKeys(it).isEmpty() }
                if (slot == null) {
                    toast("组合位已满（${Prefs.MIX_COUNT} 个）")
                    return@setPositiveButton
                }
                val keys = listOf(button) + extra
                prefs.setMixKeys(slot, keys)
                pickAction("${keys.joinToString(" + ") { Prefs.buttonLabel(it) }} → 映射动作") { picked ->
                    prefs.setMixAction(slot, picked)
                    if (picked == Action.KEY_COMBO) {
                        editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                            prefs.setMixValue(slot, v)
                            rebuild()
                        }
                    } else {
                        rebuild()
                    }
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    /** edit the keys of an existing combo; this button always stays in it */
    private fun editMixKeys(slot: Int) {
        val labels = Prefs.BUTTONS.map { Prefs.buttonLabel(it) }.toTypedArray()
        val selected = BooleanArray(Prefs.BUTTONS.size) { prefs.mixKeys(slot).contains(Prefs.BUTTONS[it]) }
        AlertDialog.Builder(this)
            .setTitle("组合：选择要同时按住的按键")
            .setMultiChoiceItems(labels, selected) { _, which, checked -> selected[which] = checked }
            .setPositiveButton("保存按键") { _, _ ->
                var keys = Prefs.BUTTONS.filterIndexed { idx, _ -> selected[idx] }
                if (keys.size < 2) {
                    toast("至少选择 2 个按键")
                    return@setPositiveButton
                }
                if (button !in keys) keys = listOf(button) + keys
                prefs.setMixKeys(slot, keys)
                pickAction("${Prefs.buttonLabel(button)} + … → 映射动作") { picked ->
                    prefs.setMixAction(slot, picked)
                    if (picked == Action.KEY_COMBO) {
                        editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                            prefs.setMixValue(slot, v)
                            rebuild()
                        }
                    } else {
                        rebuild()
                    }
                }
            }
            .setNeutralButton("删除组合") { _, _ ->
                prefs.setMixKeys(slot, emptyList())
                prefs.setMixAction(slot, Action.NONE)
                rebuild()
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun mixActionLabel(slot: Int): String {
        val action = prefs.mixAction(slot)
        return if (action == Action.KEY_COMBO) {
            "键盘快捷键（${KeyCombo.pretty(prefs.mixValue(slot))}）"
        } else {
            Action.label(action)
        }
    }

    private fun summaryOf(btn: String): String {
        val action = prefs.action(btn)
        return if (action == Action.KEY_COMBO) {
            "键盘快捷键（${KeyCombo.pretty(prefs.combo(btn))}）"
        } else {
            Action.label(action)
        }
    }

    private fun pickAction(title: String, onPicked: (String) -> Unit) {
        val labels = Action.all.map { Action.label(it) }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle(title)
            .setItems(labels) { _, which -> onPicked(Action.all[which]) }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun editCombo(title: String, current: String, onSave: (String) -> Unit) {
        val input = EditText(this).apply {
            setText(current)
            setSelectAllOnFocus(true)
            setHint("例如 ctrl+alt+f、alt+tab、win+d、f5")
            setSingleLine(true)
        }
        val box = FrameLayout(this)
        val lp = FrameLayout.LayoutParams(
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
                    toast("无法识别的快捷键：$combo")
                } else if (combo.isNotEmpty()) {
                    onSave(combo)
                    rebuild()
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    // ------------------------------------------------------------------ views

    private fun header(title: String, summary: String): View {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(14), dp(18), dp(6))
        }
        box.addView(TextView(this).apply {
            text = title
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            setTypeface(typeface, Typeface.BOLD)
        })
        box.addView(TextView(this).apply {
            text = summary
            setTextColor(SUB)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        })
        return box
    }

    private fun info(msg: String): View = TextView(this).apply {
        text = msg
        setTextColor(SUB)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
        setPadding(dp(18), dp(8), dp(18), dp(12))
    }

    private fun card(vararg rows: View): View {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF1B1B1B.toInt())
            setPadding(0, dp(4), 0, dp(4))
        }
        val lp = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        lp.topMargin = dp(10)
        box.layoutParams = lp
        rows.forEach { box.addView(it) }
        return box
    }

    private fun divider() = View(this).apply {
        setBackgroundColor(DIVIDER)
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            Math.max(1, (resources.displayMetrics.density * 0.5f).toInt()),
        ).apply { leftMargin = dp(18) }
    }

    private fun toast(text: String) {
        Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
}
