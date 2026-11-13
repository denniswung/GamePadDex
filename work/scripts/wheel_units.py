import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
old = """                        wheelAcc -= steps
                        touchActivity()
                        r.wheel(steps)"""
assert old in s, "wheel send block not found"
new = """                        wheelAcc -= steps
                        touchActivity()
                        // the helper's virtual mouse declares REL_WHEEL_HI_RES, so a
                        // "step" here must be converted to hi-res units (1 notch = 120)
                        r.wheel(steps * 120)"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("wheel steps are now 1 notch = 120 hi-res units")