import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
# restore the working discrete swipe path
s = s.replace("if (false && (sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {",
              "if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {", 1)
# disable the continuous driver (it does not dispatch reliably on this device)
s = s.replace("        continuousScroll(now, sx, sy)",
              "        // continuousScroll(now, sx, sy)   // disabled: strokes were not delivered", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("rolled back to the 95ms discrete swipe")