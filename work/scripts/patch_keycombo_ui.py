import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
s = io.open(p, encoding="utf-8").read()
# label for key_combo shows the stored combo
s = s.replace('        "scroll_up", "scroll_down" -> getString(R.string.scroll_speed)',
              '''        "scroll_up", "scroll_down" -> getString(R.string.scroll_speed)
        "key_combo" -> getString(R.string.action_key_combo)''', 1)
# after picking key_combo, ask for the combo string
old = """                prefs.edit().putString(Prefs.btnType(name), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = actionLabel(actions[which])"""
new = """                prefs.edit().putString(Prefs.btnType(name), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = actionLabel(actions[which])
                if (actions[which] == "key_combo") askCombo(actions[which]) { combo ->
                    prefs.edit().putString(Prefs.btnValue(name), combo).apply()
                    (row.findViewWithTag<TextView>("value"))?.text = combo
                }"""
assert old in s, "button picker block"
s = s.replace(old, new, 1)
# same for combos
old2 = """                prefs.edit().putString(Prefs.comboType(i), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)"""
new2 = """                prefs.edit().putString(Prefs.comboType(i), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)
                if (actions[which] == "key_combo") askCombo(actions[which]) { combo ->
                    prefs.edit().putString(Prefs.comboValue(i), combo).apply()
                    (row.findViewWithTag<TextView>("value"))?.text = combo
                }"""
assert old2 in s, "combo picker block"
s = s.replace(old2, new2, 1)
# helper dialog
if "private fun askCombo" not in s:
    helper = '''
    private fun askCombo(action: String, onValue: (String) -> Unit) {
        val input = android.widget.EditText(this).apply {
            hint = "ctrl+alt+f"
            setText(prefs.getString(Prefs.btnValue("_last_combo"), "ctrl+alt+f") ?: "ctrl+alt+f")
            setPadding(dp(16), dp(8), dp(16), dp(8))
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.action_key_combo))
            .setView(input)
            .setPositiveButton(R.string.ok) { _, _ ->
                val v = input.text.toString().trim().lowercase(Locale.US)
                prefs.edit().putString(Prefs.btnValue("_last_combo"), v).apply()
                onValue(v)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

'''
    s = s.replace("    private fun showComboKeyPicker(", helper + "    private fun showComboKeyPicker(", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("ui combo ok")