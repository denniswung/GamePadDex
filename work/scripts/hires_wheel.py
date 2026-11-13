import io
root = r"E:\Dennis\GamePadDex复刻\project"

cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()

# hi-res wheel defines
if "REL_WHEEL_HI_RES" not in c:
    c = c.replace("#include <linux/input.h>",
"""#include <linux/input.h>
#ifndef REL_WHEEL_HI_RES
#define REL_WHEEL_HI_RES 0x0b
#endif
#ifndef REL_HWHEEL_HI_RES
#define REL_HWHEEL_HI_RES 0x0c
#endif""", 1)

# try to declare the hi-res capability when creating the virtual mouse
if "g_hires_wheel" not in c:
    c = c.replace("static int g_mouse = -1;", "static int g_mouse = -1;\nstatic int g_hires_wheel = 0;", 1)
    c = c.replace("    ioctl(fd, UI_SET_RELBIT, REL_X);",
"""    if (ioctl(fd, UI_SET_RELBIT, REL_WHEEL_HI_RES) == 0) g_hires_wheel = 1;
    ioctl(fd, UI_SET_RELBIT, REL_X);""", 1)

# cmd_wheel: emit hi-res units when available, otherwise whole notches
old_wheel = """static void cmd_wheel(int n, int horizontal) {"""
assert old_wheel in c
i = c.index(old_wheel)
j = c.index("\n}\n", i) + 3
new_wheel = """static void cmd_wheel(int n, int horizontal) {
    if (g_mouse < 0) return;
    if (n == 0) return;
    if (g_hires_wheel) {
        /* one notch == 120 hi-res units: emitting small deltas scrolls smoothly */
        ev_emit(g_mouse, EV_REL, horizontal ? REL_HWHEEL_HI_RES : REL_WHEEL_HI_RES, n);
    } else {
        int notches = n / 120;
        if (notches == 0) notches = (n > 0) ? 1 : -1;
        ev_emit(g_mouse, EV_REL, horizontal ? REL_HWHEEL : REL_WHEEL, notches);
    }
    ev_syn(g_mouse);
}
"""
c = c[:i] + new_wheel + c[j:]
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("hi-res wheel added")

# Kotlin: accumulate in hi-res units
p = root + r"\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace("wheelAcc += (-sy) * (0.10f + 1.10f * scrollMag) * (scrollSpeed / 2f)",
              "wheelAcc += (-sy) * (2.0f + 22.0f * scrollMag) * (scrollSpeed / 2f)", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("app accumulates hi-res units")