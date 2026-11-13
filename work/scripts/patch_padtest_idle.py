import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/padtest/app/src/main/java/com/dennis/padtest/ui/"
def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

L = B + "LogActivity.kt"
rep(L, """    private val refresh = object : Runnable {
        override fun run() {
            if (!paused) adapter.reload()
            countView.text = "共 ${ProbeBus.count()} 条" + if (paused) "（已暂停）" else ""
            handler.postDelayed(this, 400)
        }
    }""",
"""    private var lastCount = -1

    private val refresh = object : Runnable {
        override fun run() {
            // 只在有新事件时才刷新：界面保持静止，uiautomator dump 才不会因为
            // “永不空闲”而失败（自动化测试需要能读到这里按钮的文字）
            val n = ProbeBus.count()
            if (!paused && n != lastCount) {
                lastCount = n
                adapter.reload()
            }
            val text = "共 $n 条" + if (paused) "（已暂停）" else ""
            if (countView.text != text) countView.text = text
            handler.postDelayed(this, 400)
        }
    }""", "log tick")

R = B + "ReportActivity.kt"
rep(R, """    private val tick = object : Runnable {
        override fun run() {
            render()
            handler.postDelayed(this, 500)
        }
    }""",
"""    private var lastFingerprint = ""

    private val tick = object : Runnable {
        override fun run() {
            val (p, f, u) = CheckRegistry.counts()
            val fp = "$p-$f-$u-" + CheckRegistry.sessionStart(this@ReportActivity) +
                "-" + CheckRegistry.sessionStop(this@ReportActivity) + "-" + ProbeBus.count()
            if (fp != lastFingerprint) {
                lastFingerprint = fp
                render()
            }
            handler.postDelayed(this, 500)
        }
    }""", "report tick")
print("done")
