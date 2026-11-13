import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
BD = B + "ButtonDetailActivity.kt"; CA = B + "ConfigActivity.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# --- ButtonDetail: long-press action row ---
rep(BD, """            header("双击动作", "连续按两下 ${Prefs.buttonLabel(button)}（320 ms 内）时触发"),
            actionRow("双击动作", doubleSummary()) { pickDouble() },
        ))""",
"""            header("双击动作", "连续按两下 ${Prefs.buttonLabel(button)}（320 ms 内）时触发"),
            actionRow("双击动作", doubleSummary()) { pickDouble() },
            divider(),
            header("长按动作", "按住 ${Prefs.buttonLabel(button)} 超过 ${prefs.longMs()} ms 时触发（会取消单击/双击）"),
            actionRow("长按动作", longSummary()) { pickLong() },
        ))""", "detail long row")

rep(BD, """    private fun pickDouble() {""",
"""    private fun longSummary(): String {
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

    private fun pickDouble() {""", "detail long picker")

# --- ConfigActivity: pointer sliders ---
rep(CA, """            sliderRow("精准移动（X+左摇杆）", 5, 50, prefs.precisionScale, "% 速度") { v -> prefs.precisionScale = v },""",
"""            sliderRow("精准移动（X+左摇杆）", 5, 50, prefs.precisionScale, "% 速度") { v -> prefs.precisionScale = v },
            sliderRow("水平灵敏度 X", 20, 300, (prefs.sensX() * 100).toInt(), "%") { v -> prefs.setSensX(v) },
            sliderRow("垂直灵敏度 Y", 20, 300, (prefs.sensY() * 100).toInt(), "%") { v -> prefs.setSensY(v) },
            sliderRow("边缘减速", 0, 60, prefs.edgeSlow(), "%") { v -> prefs.setEdgeSlow(v) },""", "pointer sliders")

# --- ConfigActivity: data card + rebuild hook ---
rep(CA, """        buildMapping()
        buildFooter()""",
"""        buildMapping()
        buildData()
        buildFooter()""", "rebuild data")

rep(CA, """    private fun buildFooter() {""",
"""    private fun buildData() {
        content.addView(card(
            actionButton("导出配置…") { exportConfig() },
            divider(),
            actionButton("导入配置…") { importConfig() },
            divider(),
            actionButton("保存为 Profile…") { saveProfileDialog() },
            divider(),
            actionButton("加载 Profile…") { loadProfileDialog() },
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
        promptText("保存 Profile", "") { name ->
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

    private fun buildFooter() {""", "data ui")

print("done")
