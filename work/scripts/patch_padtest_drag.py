import io, sys
A = "/mnt/e/Dennis/GamePadDex复刻/project/padtest/app/src/main/java/com/dennis/padtest/ui/ProbeActivity.kt"
s = io.open(A, encoding="utf-8").read()

old = '''            MotionEvent.ACTION_UP -> emit(
                ProbeEvent(
                    src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                    kind = if (fromMouse) "click-up" else "touch-up",
                    detail = "x=${ev.x.toInt()} y=${ev.y.toInt()}",
                ),
            )'''
new = '''            MotionEvent.ACTION_UP -> {
                val dx = ev.x - downX
                val dy = ev.y - downY
                val dist = kotlin.math.hypot(dx.toDouble(), dy.toDouble()).toFloat()
                val moved = dist > 40f
                emit(
                    ProbeEvent(
                        src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                        kind = if (moved) "drag" else if (fromMouse) "click-up" else "touch-up",
                        detail = "x=${ev.x.toInt()} y=${ev.y.toInt()} dx=${dx.toInt()} dy=${dy.toInt()} dist=${dist.toInt()}",
                        extra = mapOf("dx" to dx.toString(), "dy" to dy.toString(), "dist" to dist.toString()),
                    ),
                )
                // 位移足够大时额外记一条「手势滑动」，方便与滚轮后端区分
                if (moved) {
                    emit(
                        ProbeEvent(
                            src = Src.TOUCH,
                            kind = "swipe",
                            detail = "dx=${dx.toInt()} dy=${dy.toInt()} dist=${dist.toInt()}",
                            extra = mapOf("dx" to dx.toString(), "dy" to dy.toString()),
                        ),
                    )
                }
            }'''
if old not in s:
    print("MISS up"); sys.exit(1)
s = s.replace(old, new, 1)

old2 = '''            MotionEvent.ACTION_DOWN -> emit(
                ProbeEvent(
                    src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                    kind = if (fromMouse) "click-down" else "touch-down",
                    detail = "x=${ev.x.toInt()} y=${ev.y.toInt()} btn=${ev.buttonState}",
                ),
            )'''
new2 = '''            MotionEvent.ACTION_DOWN -> {
                downX = ev.x
                downY = ev.y
                emit(
                    ProbeEvent(
                        src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                        kind = if (fromMouse) "click-down" else "touch-down",
                        detail = "x=${ev.x.toInt()} y=${ev.y.toInt()} btn=${ev.buttonState}",
                    ),
                )
            }'''
if old2 not in s:
    print("MISS down"); sys.exit(1)
s = s.replace(old2, new2, 1)

s = s.replace("    private val keyDownAt = HashMap<Int, Long>()",
              "    private val keyDownAt = HashMap<Int, Long>()\n    private var downX = 0f\n    private var downY = 0f", 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(s)
print("probe ok")
