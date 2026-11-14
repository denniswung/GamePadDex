import io, sys
BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
A = BASE + "ActionRouter.kt"
B = BASE + "ButtonDetailActivity.kt"
C = BASE + "ConfigActivity.kt"

# ---------------- ActionRouter：OPEN_APP 用槽参数 ----------------
a = io.open(A, encoding="utf-8").read()
old = '''            Action.OPEN_APP -> {
                val pkg = prefs.targetPackage
                if (pkg.isBlank()) log("open app: 目标应用未设置")
                else {
                    host.launchApp(pkg)
                    log("open app $pkg")
                }
            }'''
new = '''            Action.OPEN_APP -> {
                // 每个映射槽自己配的目标包名（空则回退到全局设置）
                val pkg = comboValue.ifBlank { prefs.targetPackage }
                if (pkg.isBlank()) log("open app: 该按键还没选目标应用")
                else {
                    host.launchApp(pkg)
                    log("open app $pkg")
                }
            }'''
if old not in a:
    print("MISS router"); sys.exit(1)
a = a.replace(old, new, 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(a)
print("router ok")

# ---------------- ButtonDetailActivity：每个槽选 App ----------------
b = io.open(B, encoding="utf-8").read()

if "pickApp(" not in b:
    # 在 pickAction 附近插入 App 选择器
    b = b.replace("    private fun actionRow(label: String, value: String, onClick: () -> Unit): View {",
'''    /** 选目标应用（给 OPEN_APP 用）：返回 (label, package) 列表对话框 */
    private fun pickApp(title: String, current: String, onPick: (String) -> Unit) {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = pm.queryIntentActivities(intent, 0)
            .map { it.loadLabel(pm).toString() to it.activityInfo.packageName }
            .distinctBy { it.second }
            .sortedBy { it.first }
        val items = apps.map {
            val mark = if (it.second == current) "✓ " else ""
            "$mark${it.first}\\n${it.second}"
        }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle(title)
            .setItems(items) { _, i -> onPick(apps[i].second) }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun appLabel(pkg: String): String {
        if (pkg.isBlank()) return "未选择应用（点击选择）"
        return try {
            val pm = packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString() + "\\n" + pkg
        } catch (_: Throwable) {
            pkg
        }
    }

    private fun actionRow(label: String, value: String, onClick: () -> Unit): View {''', 1)

    # 单击：选到 OPEN_APP 后弹应用选择器
    b = b.replace('''                if (picked == Action.KEY_COMBO) {
                    editCombo("${Prefs.buttonLabel(button)} 的键盘快捷键", prefs.combo(button)) { v ->
                        prefs.setCombo(button, v)
                    }
                } else {
                    rebuild()
                }''',
'''                when (picked) {
                    Action.KEY_COMBO -> editCombo("${Prefs.buttonLabel(button)} 的键盘快捷键", prefs.combo(button)) { v ->
                        prefs.setCombo(button, v)
                    }
                    Action.OPEN_APP -> pickApp("${Prefs.buttonLabel(button)} → 打开哪个应用", prefs.param(button)) { v ->
                        prefs.setParam(button, v)
                        rebuild()
                    }
                    else -> rebuild()
                }''', 1)

    # 长按：用 paramLng
    b = b.replace('''            if (picked == Action.KEY_COMBO) {
                editCombo("${Prefs.buttonLabel(button)} 长按的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
            } else {
                rebuild()
            }''',
'''            when (picked) {
                Action.KEY_COMBO -> editCombo("${Prefs.buttonLabel(button)} 长按的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
                Action.OPEN_APP -> pickApp("${Prefs.buttonLabel(button)} 长按 → 打开哪个应用", prefs.paramLng(button)) { v ->
                    prefs.setParamLng(button, v)
                    rebuild()
                }
                else -> rebuild()
            }''', 1)

    # 双击：用 paramDbl
    b = b.replace('''            if (picked == Action.KEY_COMBO) {
                editCombo("${Prefs.buttonLabel(button)} 双击的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
            } else {
                rebuild()
            }''',
'''            when (picked) {
                Action.KEY_COMBO -> editCombo("${Prefs.buttonLabel(button)} 双击的键盘快捷键", prefs.combo(button)) { v ->
                    prefs.setCombo(button, v)
                }
                Action.OPEN_APP -> pickApp("${Prefs.buttonLabel(button)} 双击 → 打开哪个应用", prefs.paramDbl(button)) { v ->
                    prefs.setParamDbl(button, v)
                    rebuild()
                }
                else -> rebuild()
            }''', 1)

    # 摘要里显示已选应用
    b = b.replace('''            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            else -> Action.label(d)''',
'''            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            Action.OPEN_APP -> "打开应用（${appLabel(prefs.paramDbl(button)).replace("\\n", " ") }）"
            else -> Action.label(d)''', 1)
    b = b.replace('''            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            else -> Action.label(d)''',
'''            Action.KEY_COMBO -> "键盘快捷键（${KeyCombo.pretty(prefs.combo(button))}）"
            Action.OPEN_APP -> "打开应用（${appLabel(prefs.paramLng(button)).replace("\\n", " ") }）"
            else -> Action.label(d)''', 1)

    # 组合槽：选到 OPEN_APP 后弹选择器（写下 mixValue）
    b = b.replace('''        if (picked == Action.KEY_COMBO) {
            editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                prefs.setMixValue(slot, v)
            }
        }''',
'''        when (picked) {
            Action.KEY_COMBO -> editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                prefs.setMixValue(slot, v)
            }
            Action.OPEN_APP -> pickApp("组合 → 打开哪个应用", prefs.mixValue(slot)) { v ->
                prefs.setMixValue(slot, v)
                rebuild()
            }
        }''')

    if "import android.app.AlertDialog" not in b:
        b = b.replace("import android.os.Bundle", "import android.app.AlertDialog\nimport android.content.Intent\nimport android.os.Bundle", 1)

    io.open(B, "w", encoding="utf-8", newline="\n").write(b)
    print("button detail ok")

# ---------------- ConfigActivity：去掉全局目标应用行（改为每槽配置） ----------------
c = io.open(C, encoding="utf-8").read()
c = c.replace("        buildTargetApp()\n", "", 1)
io.open(C, "w", encoding="utf-8", newline="\n").write(c)
print("config row removed")
