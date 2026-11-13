import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
C = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

p = io.open(P, encoding="utf-8").read()
if "centerGain" not in p:
    p = p.replace('        const val KEY_IDLE_HIDE_SEC = "idle_hide_sec"',
                  '        const val KEY_IDLE_HIDE_SEC = "idle_hide_sec"\n        const val KEY_CENTER_GAIN = "center_gain"', 1)
    p = p.replace("    /** 空闲多少秒后隐藏系统指针（0 = 不隐藏） */",
"""    /** 居中时 raw 单位 → 屏幕像素 的增益（实测约 2.16；指针加速不同会变） */
    val centerGain: Float
        get() = shared.getInt(KEY_CENTER_GAIN, 216).coerceIn(100, 400) / 100f

    fun setCenterGain(v: Int) = shared.edit().putInt(KEY_CENTER_GAIN, v.coerceIn(100, 400)).apply()

    /** 空闲多少秒后隐藏系统指针（0 = 不隐藏） */""", 1)
    io.open(P, "w", encoding="utf-8", newline="\n").write(p)
    print("prefs ok")

e = io.open(E, encoding="utf-8").read()
if "prefs.centerGain" not in e:
    e = e.replace("                val dx = (vw / 2f - ptrX) / RAW_TO_PX\n                val dy = (vh / 2f - ptrY) / RAW_TO_PX",
                  "                val gain = prefs.centerGain\n                val dx = (vw / 2f - ptrX) / gain\n                val dy = (vh / 2f - ptrY) / gain", 1)
    e = e.replace("                ptrX = (ptrX + mx * RAW_TO_PX).coerceIn(0f, vw.toFloat())\n                ptrY = (ptrY + my * RAW_TO_PX).coerceIn(0f, vh.toFloat())",
                  "                val g = prefs.centerGain\n                ptrX = (ptrX + mx * g).coerceIn(0f, vw.toFloat())\n                ptrY = (ptrY + my * g).coerceIn(0f, vh.toFloat())", 1)
    e = e.replace('                Log.i(TAG, "center pointer dx=${dx.toInt()} dy=${dy.toInt()} -> ${vw / 2},${vh / 2}")',
                  '                Log.i(TAG, "center pointer dx=${dx.toInt()} dy=${dy.toInt()} gain=$gain -> ${vw / 2},${vh / 2}")', 1)
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
    print("engine ok")

c = io.open(C, encoding="utf-8").read()
if "居中增益" not in c:
    c = c.replace('            sliderRow("空闲隐藏指针", 0, 30,',
'''            sliderRow("居中增益", 100, 400, (prefs.centerGain * 100).toInt(), " %") { v -> prefs.setCenterGain(v) },
            sliderRow("空闲隐藏指针", 0, 30,''', 1)
    io.open(C, "w", encoding="utf-8", newline="\n").write(c)
    print("config ok")
