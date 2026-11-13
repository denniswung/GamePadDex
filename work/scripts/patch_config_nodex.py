import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"
s = io.open(p, encoding="utf-8").read()

s = s.replace('''            switchRow(
                "连接有线 DeX 时自动开启",
                "插入 HDMI 后自动进入鼠标模式",
                prefs.autoDex,
            ) { v -> prefs.autoDex = v },
            switchRow(
                "手机上也启用（非 DeX）",
                "不接 DeX 时也把手柄当鼠标/键盘用",
                prefs.phoneMode,
            ) { v -> prefs.phoneMode = v },
''', "")

s = s.replace('''        statusDeX = valueView()
''', "")
s = s.replace('''            infoRow("有线 DeX", statusDeX!!),
''', "")
s = s.replace('''            sliderRow("DeX 指针速度", 5, 100, prefs.speedDex, " px/帧") { v -> prefs.speedDex = v },
''', "")
s = s.replace('''        statusDeX?.text = if (EngineState.dexConnected) "已连接" else "未连接"
''', "")
s = s.replace("    private var statusDeX: TextView? = null\n", "")
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("config patched")
