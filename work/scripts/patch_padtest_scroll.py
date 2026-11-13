import io, sys
S = "/mnt/e/Dennis/GamePadDex复刻/project/padtest/app/src/main/java/com/dennis/padtest/ui/ScrollTestActivity.kt"
s = io.open(S, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

rep("""    private var touchSwipes = 0""",
"""    private var touchSwipes = 0
    private var gestureScrolls = 0
    private var wheelScrolls = 0
    private var bridgeGesture = true""", "fields")

rep("""    override fun onProbeEvent(e: ProbeEvent) {
        when (e.src) {
            Src.WHEEL -> {
                wheelEvents++
                refresh()
            }
            Src.TOUCH -> {
                if (e.kind == "touch-up") touchSwipes++
                refresh()
            }
            else -> Unit
        }
    }""",
"""    override fun onProbeEvent(e: ProbeEvent) {
        when {
            e.src == Src.WHEEL -> {
                wheelEvents++
                wheelScrolls++
                refresh()
            }
            e.src == Src.TOUCH && e.kind == "swipe" -> {
                // 手势后端：把滑动位移应用到列表上（探针模式），让「有没有真的滚」可见
                touchSwipes++
                gestureScrolls++
                if (bridgeGesture) {
                    val dy = e.extra["dy"]?.toFloatOrNull() ?: 0f
                    val dx = e.extra["dx"]?.toFloatOrNull() ?: 0f
                    if (kotlin.math.abs(dy) >= kotlin.math.abs(dx)) {
                        vList.smoothScrollBy(0, -dy.toInt())
                    } else {
                        hScroll.smoothScrollBy(-dx.toInt(), 0)
                    }
                }
                refresh()
            }
            else -> Unit
        }
    }""", "event handling")

rep("""        backendState.text = "后端统计：触摸滑动 $touchSwipes 次 · 滚轮 $wheelEvents 次（看日志颜色区分）"
        if (wheelEvents > 0 && touchSwipes > 0) {
            CheckRegistry.pass("SCROLL.BACKEND", "两种后端都出现过")
        }""",
"""        backendState.text = "后端统计：手势滑动 $touchSwipes 次（已应用到列表 ${if (bridgeGesture) "开" else "关"}）" +
            " · 滚轮 $wheelEvents 次"
        if (touchSwipes > 0) CheckRegistry.pass("SCROLL.GESTURE", "手势滑动 $touchSwipes 次")
        if (wheelEvents > 0) CheckRegistry.pass("SCROLL.WHEEL", "滚轮 $wheelEvents 次")""", "backend text")

rep("""        CheckRegistry.define("SCROLL.BACKEND", "滚动", "手势/滚轮两种后端可区分")""",
"""        CheckRegistry.define("SCROLL.BACKEND", "滚动", "手势/滚轮两种后端可区分")
        CheckRegistry.define("SCROLL.GESTURE", "滚动", "手势后端产生滑动")
        CheckRegistry.define("SCROLL.WHEEL", "滚动", "滚轮后端产生滚动")""", "checks")

io.open(S, "w", encoding="utf-8", newline="\n").write(s)
print("done")
