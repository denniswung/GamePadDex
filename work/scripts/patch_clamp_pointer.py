import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"

e = io.open(E, encoding="utf-8").read()

# 1) 发送位移前按"跟踪位置"夹住，避免把系统指针推出屏幕（推出去就再也回不来，
#    表现就是光标消失/点了没反应）
old = '''                // 亚像素抖动不发：1px 的残余移动在慢速下会被看成“滑”
                if (Math.abs(mx) < 0.6f && Math.abs(my) < 0.6f) return
                root.move(mx, my)'''
new = '''                // 亚像素抖动不发：1px 的残余移动在慢速下会被看成“滑”
                if (Math.abs(mx) < 0.6f && Math.abs(my) < 0.6f) return
                // 按"引擎跟踪到的位置"把这一帧的位移夹在屏幕内：系统不会把注入的
                // REL 位移夹回屏幕，一旦推出去，光标就再也不出现（点击全部落空）。
                val gNow = prefs.centerGain
                val rx = mx.coerceIn((0f - ptrX) / gNow, (vw - ptrX) / gNow)
                val ry = my.coerceIn((0f - ptrY) / gNow, (vh - ptrY) / gNow)
                if (Math.abs(rx) < 0.01f && Math.abs(ry) < 0.01f) return
                root.move(rx, ry)'''
if old not in e:
    print("MISS clamp anchor"); sys.exit(1)
e = e.replace(old, new, 1)
print("clamp ok")

# 2) 后面的跟踪与日志改用 rx/ry
e = e.replace('''                val nowPtr = SystemClock.elapsedRealtime()
                if (nowPtr - lastPtrLogAt > 300) {
                    lastPtrLogAt = nowPtr
                    Log.i(TAG, "ptr move dx=${mx.toInt()} dy=${my.toInt()} sens=${prefs.sensX()}")
                }
                val g = prefs.centerGain
                ptrX = (ptrX + mx * g).coerceIn(0f, vw.toFloat())
                ptrY = (ptrY + my * g).coerceIn(0f, vh.toFloat())''',
'''                val nowPtr = SystemClock.elapsedRealtime()
                if (nowPtr - lastPtrLogAt > 300) {
                    lastPtrLogAt = nowPtr
                    Log.i(TAG, "ptr move dx=${rx.toInt()} dy=${ry.toInt()} at ${ptrX.toInt()},${ptrY.toInt()}")
                }
                ptrX = (ptrX + rx * gNow).coerceIn(0f, vw.toFloat())
                ptrY = (ptrY + ry * gNow).coerceIn(0f, vh.toFloat())''', 1)
print("track ok")

# 3) 居中后把跟踪位置重置到中心（否则引擎的"当前位置"和实际脱节）
if "override fun onCentered()" not in e:
    anchor = "            override fun launchApp(pkg: String) = launchTargetApp(pkg)"
    if anchor not in e:
        print("MISS host anchor"); sys.exit(1)
    e = e.replace(anchor, anchor + '''

            override fun onCentered() {
                val (vw, vh) = displaySize(activeDisplay())
                ptrX = vw / 2f
                ptrY = vh / 2f
                lastUserInputAt = SystemClock.elapsedRealtime()
            }''', 1)
    print("host onCentered ok")

io.open(E, "w", encoding="utf-8", newline="\n").write(e)

a = io.open(A, encoding="utf-8").read()
if "fun onCentered()" not in a:
    a = a.replace("        /** 启动\"目标应用\"动作里配置的包 */",
                  "        /** 光标已经被居中：引擎要把自己的位置估计重置到屏幕中心 */\n        fun onCentered()\n\n        /** 启动\"目标应用\"动作里配置的包 */", 1)
    a = a.replace("                root.centerCursor(w, h, host.isPhone(), rot, gain)",
                  "                root.centerCursor(w, h, host.isPhone(), rot, gain)\n                host.onCentered()", 1)
    io.open(A, "w", encoding="utf-8", newline="\n").write(a)
    print("router onCentered ok")
