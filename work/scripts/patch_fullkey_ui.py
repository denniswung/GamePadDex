import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
mp = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse", "MainActivity.kt")
s = io.open(mp, encoding="utf-8").read()

if "bindFullKeyMapping" not in s:
    ui = """
    // ---------------- full-key + combo mapping UI ----------------
    private fun bindFullKeyMapping() {
        val anchor = findViewById<View>(R.id.btn_map_x_lb)
        val parent = anchor.parent as? LinearLayout ?: return
        parent.addView(uiSection(getString(R.string.full_key_mapping_title)))
        parent.addView(uiDesc(getString(R.string.full_key_mapping_hint)))
        for (name in Prefs.BUTTONS) {
            val row = uiRow(buttonLabel(name), actionLabelOf(prefs.getString(Prefs.btnType(name), "default")))
            row.tag = name
            row.setOnClickListener { showButtonActionPicker(name, row) }
            parent.addView(row)
        }
        parent.addView(uiSection(getString(R.string.combos_title)))
        for (i in 0 until Prefs.COMBO_COUNT) {
            val row = uiRow(comboLabel(i), comboActionLabel(i))
            row.tag = i
            row.setOnClickListener { showComboKeyPicker(i, row) }
            parent.addView(row)
        }
    }

    private fun buttonLabel(name: String): String = when (name) {
        "l3" -> "L3"; "r3" -> "R3"; "lb" -> "LB"; "rb" -> "RB"; "lt" -> "LT"; "rt" -> "RT"
        else -> name.uppercase(Locale.US)
    }

    private fun comboLabel(i: Int): String {
        val keys = prefs.getString(Prefs.comboKeys(i), "") ?: ""
        return getString(
            R.string.combo_row_format, i + 1,
            if (keys.isBlank()) getString(R.string.combo_empty) else keys.split("+").joinToString(" + ") { buttonLabel(it.trim()) }
        )
    }

    private fun comboActionLabel(i: Int): String {
        val t = prefs.getString(Prefs.comboType(i), "none") ?: "none"
        return if (t == "none" || t == "default") getString(R.string.action_none) else actionLabel(t)
    }

    private fun actionLabel(action: String): String = when (action) {
        "default" -> getString(R.string.action_default)
        "mouse_click" -> getString(R.string.action_click_location)   // reuse label
        "back" -> getString(R.string.action_home)
        "toggle_mouse" -> getString(R.string.mouse_service_enabled)
        "scroll_up", "scroll_down" -> getString(R.string.scroll_speed)
        else -> getString(actionLabelRes(action))
    }

    private fun uiSection(text: String): TextView = TextView(this, null, 0, R.style.GpmSection).apply {
        this.text = text
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(18) }
    }

    private fun uiDesc(text: String): TextView = TextView(this, null, 0, R.style.GpmDesc).apply {
        this.text = text
    }

    private fun uiRow(label: String, value: String): LinearLayout {
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL
        row.setPadding(0, dp(12), 0, dp(12))
        row.isClickable = true
        val l = TextView(this, null, 0, R.style.GpmLabel).apply { text = label }
        val v = TextView(this, null, 0, R.style.GpmValue).apply {
            text = value
            tag = "value"
        }
        row.addView(l, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(v, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ))
        return row
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun showButtonActionPicker(name: String, row: LinearLayout) {
        val actions = listOf("default") + Prefs.ACTIONS + Prefs.EXTRA_ACTIONS
        val labels = actions.map { actionLabel(it) }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(buttonLabel(name))
            .setItems(labels) { _, which ->
                prefs.edit().putString(Prefs.btnType(name), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = actionLabel(actions[which])
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showComboKeyPicker(i: Int, row: LinearLayout) {
        val names = Prefs.BUTTONS
        val labels = names.map { buttonLabel(it) }.toTypedArray()
        val current = (prefs.getString(Prefs.comboKeys(i), "") ?: "").split("+")
            .mapNotNull { k -> names.indexOfFirst { it == k.trim() }.takeIf { it >= 0 } }
            .toBooleanArray()
        val checked = BooleanArray(names.size) { current.getOrElse(it) { false } }
        MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.combo_keys_title))
            .setMultiChoiceItems(labels, checked) { _, which, isChecked -> checked[which] = isChecked }
            .setPositiveButton(R.string.ok) { _, _ ->
                val keys = names.filterIndexed { idx, _ -> checked[idx] }.joinToString("+")
                prefs.edit().putString(Prefs.comboKeys(i), keys).apply()
                val comboRow = row
                if (keys.isBlank()) {
                    prefs.edit().putString(Prefs.comboType(i), "none").apply()
                    (comboRow.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)
                } else {
                    showComboActionPicker(i, comboRow)
                }
                (comboRow.getChildAt(0) as TextView).text = comboLabel(i)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showComboActionPicker(i: Int, row: LinearLayout) {
        val actions = listOf("none") + Prefs.ACTIONS + Prefs.EXTRA_ACTIONS
        val labels = actions.map { actionLabel(it) }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(comboLabel(i))
            .setItems(labels) { _, which ->
                prefs.edit().putString(Prefs.comboType(i), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

"""
    s = s.replace("    private fun bindMappingPage() {", ui + "    private fun bindMappingPage() {", 1)
    s = s.replace("    private fun bindMappingPage() {\n", "    private fun bindMappingPage() {\n        bindFullKeyMapping()\n", 1)
    io.open(mp, "w", encoding="utf-8", newline="\n").write(s)
    print("mainactivity ok")
