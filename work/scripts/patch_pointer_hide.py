import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
D = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/DebugReceiver.kt"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"

s = io.open(H, encoding="utf-8").read()
anchor = "        case 'A': {"
if anchor not in s:
    print("MISS A"); sys.exit(1)
add = '''        case 'h': {
            /* 隐藏系统鼠标指针：销毁虚拟鼠标设备（指针图标随之消失） */
            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }
            break;
        }
        case 'j': {
            /* 重新创建虚拟鼠标（指针重新出现） */
            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }
            break;
        }
'''
s = s.replace(anchor, add + anchor, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper ok")

r = io.open(R, encoding="utf-8").read()
if "fun raw(" not in r:
    r = r.replace('    fun queryTop() = send("t")',
                  '    fun queryTop() = send("t")\n\n    /** 直接发一条助手命令（仅调试/测试用） */\n    fun raw(cmd: String) = send(cmd)', 1)
    io.open(R, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")
