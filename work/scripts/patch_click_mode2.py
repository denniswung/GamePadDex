import io, sys
BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
P, C, E = BASE + "Prefs.kt", BASE + "ConfigActivity.kt", BASE + "EngineService.kt"


def pull(path):
    return io.open(path, encoding="utf-8").read()


def push(path, s):
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)


ok = True

# ---------------- Prefs ----------------
p = pull(P)
if "leftClickTouch" in p:
    print("prefs: already")
else:
    if 'const val KEY_TARGET_PACKAGE' not in p:
        print("prefs: MISS const anchor"); ok = False
    else:
        p = p.replace('const val KEY_TARGET_PACKAGE = "target_package"',
                      'const val KEY_TARGET_PACKAGE = "target_package"\n        const val KEY_LEFT_TOUCH = "left_touch"', 1)
        # 属性插在 targetPackage 之前
        anchor = '    /** "打开目标应用"动作要启动的包名'
        if anchor not in p:
            print("prefs: MISS prop anchor"); ok = False
        else:
            p = p.replace(anchor,
'''    /**
     * 左键注入方式：
     *  false（默认）= 鼠标左键事件，系统按真实光标位置点击，最可靠；
     *  true = 在光标位置注入真实触摸（部分 App 只认触摸，但坐标来自估算，可能点偏）。
     */
    var leftClickTouch: Boolean
        get() = shared.getBoolean(KEY_LEFT_TOUCH, false)
        set(v) = shared.edit().putBoolean(KEY_LEFT_TOUCH, v).apply()

''' + anchor, 1)
            push(P, p)
            print("prefs: ok")

# ---------------- ConfigActivity ----------------
c = pull(C)
if "左键注入方式" in c:
    print("config: already")
else:
    anchor = '            sliderRow("手机指针速度"'
    if anchor not in c:
        print("config: MISS anchor"); ok = False
    else:
        c = c.replace(anchor,
'''            switchRow(
                "左键注入方式：触摸点击",
                "关（默认）= 鼠标左键，最可靠；开 = 在光标位置注入真实触摸（部分 App 只认触摸）",
                prefs.leftClickTouch,
            ) { v -> prefs.leftClickTouch = v },
''' + anchor, 1)
        push(C, c)
        print("config: ok")

# ---------------- EngineService ----------------
e = pull(E)
if "prefs.leftClickTouch" in e:
    print("engine: already")
else:
    old = '''                } else {
                    // 鼠标左键 = 在光标位置模拟一次屏幕点击（真实触摸事件，
                    // 按住不放就是长按）；这样信息流/短剧类应用也认得
                    val (px, py) = pointerPos()
                    showPointer()
                    root.touch(px, py, true)
                    leftIsTouch = true
                    pressedMouse.add(0)
                    Log.i(TAG, "left touch down at ${px.toInt()},${py.toInt()}")
                }'''
    new = '''                } else if (prefs.leftClickTouch) {
                    // 可选：在光标位置注入真实触摸（只给"只认触摸"的 App 用）
                    val (px, py) = pointerPos()
                    showPointer()
                    root.touch(px, py, true)
                    leftIsTouch = true
                    pressedMouse.add(0)
                    Log.i(TAG, "left touch down at ${px.toInt()},${py.toInt()}")
                } else {
                    // 默认：鼠标左键事件——系统按真实光标位置处理，永远点得中
                    showPointer()
                    root.button(0, true)
                    leftIsTouch = false
                    pressedMouse.add(0)
                    Log.i(TAG, "left button down")
                }'''
    if old not in e:
        print("engine: MISS anchor"); ok = False
    else:
        e = e.replace(old, new, 1)
        push(E, e)
        print("engine: ok")

print("RESULT", "ok" if ok else "FAILED")
sys.exit(0 if ok else 1)
