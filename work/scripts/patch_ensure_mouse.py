import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# 1) 统一的"确保鼠标设备存在"
if "ensure_mouse" not in s:
    s = s.replace("static void cmd_mouse_move(double dx, double dy) {\n    if (g_mouse < 0) return;",
'''/* 鼠标设备可能被「空闲隐藏」销毁了：任何一次移动/点击前都确保它存在，
 * 否则 App 侧状态一旦不同步，就会表现为「光标不见了/点了没反应」。 */
static void ensure_mouse(void) {
    if (g_mouse >= 0) return;
    g_mouse = make_mouse();
    if (g_mouse >= 0) {
        usleep(120 * 1000);
        out("MOUSE_REOPEN (auto)");
    }
}

static void cmd_mouse_move(double dx, double dy) {
    ensure_mouse();
    if (g_mouse < 0) return;''', 1)
    print("ensure_mouse ok")

# 2) 按键 / 滚轮也补齐
s = s.replace("static void cmd_mouse_button(int btn, int down) {\n    if (g_mouse < 0) return;",
              "static void cmd_mouse_button(int btn, int down) {\n    ensure_mouse();\n    if (g_mouse < 0) return;", 1)
s = s.replace("static void cmd_wheel(int n, int horizontal) {\n    if (g_mouse < 0) return;",
              "static void cmd_wheel(int n, int horizontal) {\n    ensure_mouse();\n    if (g_mouse < 0) return;", 1)

# 3) 'j' 命令复用 ensure_mouse 语义（保持兼容）
s = s.replace('''            /* 重新创建虚拟鼠标（指针重新出现） */
            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }''',
'''            /* 重新创建虚拟鼠标（指针重新出现） */
            ensure_mouse();
            out("POINTER on");''', 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper patched")

# 4) 引擎 onReady：强制重置指针状态并让助手重建鼠标
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
e = io.open(E, encoding="utf-8").read()
if 'root.raw("j")' not in e:
    anchor = '        touchSizeSent = ""\n        syncTouchSize()'
    if anchor not in e:
        print("MISS engine ready anchor")
    else:
        e = e.replace(anchor, '        touchSizeSent = ""\n        syncTouchSize()\n        // 助手重启后鼠标设备可能还是"被隐藏"状态：强制重建一次，\n        // 否则光标设备不存在，移动/点击全部静默失效。\n        pointerHidden = false\n        root.raw("j")', 1)
        io.open(E, "w", encoding="utf-8", newline="\n").write(e)
        print("engine ready ok")
