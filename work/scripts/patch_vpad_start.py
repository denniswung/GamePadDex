import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

s = io.open(H, encoding="utf-8").read()

# 1) 启动时创建虚拟手柄（HAT 输出需要它）
old = "    g_kbd = make_keyboard();"
if old not in s:
    print("MISS kbd"); sys.exit(1)
s = s.replace(old, old + "\n    g_pad = make_gamepad();", 1)

# 2) A 命令：没有虚拟手柄时退回 input keyevent，保证方向键一定生效
old2 = """            if (g_pad >= 0) {
                ev_emit(g_pad, EV_ABS, ABS_HAT0X, wantX);
                ev_emit(g_pad, EV_ABS, ABS_HAT0Y, wantY);
                ev_syn(g_pad);
            }"""
new2 = """            if (g_pad < 0) {
                /* 没有虚拟手柄：退回注入方向键（19/20/21/22） */
                int kc = (dir == 1) ? 19 : (dir == 2) ? 20 : (dir == 3) ? 21 : 22;
                if (fork() == 0) {
                    char c2[96];
                    snprintf(c2, sizeof(c2), "/system/bin/input keyevent %d", kc);
                    system(c2);
                    _exit(0);
                }
                out("HAT %d fallback=key", dir);
                break;
            }
            if (g_pad >= 0) {
                ev_emit(g_pad, EV_ABS, ABS_HAT0X, wantX);
                ev_emit(g_pad, EV_ABS, ABS_HAT0Y, wantY);
                ev_syn(g_pad);
            }"""
if old2 not in s:
    print("MISS hat emit"); sys.exit(1)
s = s.replace(old2, new2, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper ok")

# 3) App: 设备掉线（GONE）时清空按键状态，避免组合永久卡 fired
r = io.open(R, encoding="utf-8").read()
if 'startsWith("GONE' not in r:
    anchor = 'line == "HELLO"'
    if anchor in r:
        r = r.replace(anchor, 'line.startsWith("GONE ") || line.startsWith("GONE_EVT") -> onDeviceGone()\n            ' + anchor, 1)
        io.open(R, "w", encoding="utf-8", newline="\n").write(r)
        print("rootinput gone hook added")
    else:
        print("MISS hello anchor")
else:
    print("gone hook exists")
