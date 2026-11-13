import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"

# ---------------- helper ----------------
s = io.open(H, encoding="utf-8").read()

# 1) 事件循环：不再自动原生转发 d-pad，全部交给 App 决策
old_hat = """                    if (g_dpad_native && !any_btn_held() && ev->code == ABS_HAT0X) {
                        pad_hat(ABS_HAT0X, ev->value);
                        continue;
                    }
                    if (g_dpad_native && !any_btn_held() && ev->code == ABS_HAT0Y) {
                        pad_hat(ABS_HAT0Y, ev->value);
                        continue;
                    }"""
if old_hat not in s:
    print("MISS hat fwd"); sys.exit(1)
s = s.replace(old_hat, """                    /* d-pad 一律上报给 App（软件在虚拟控制器层之上）：
                     * App 决定这是组合键还是普通方向键，再由 H 命令回写到虚拟手柄 */""", 1)

old_key = """                    if (g_dpad_native && !any_btn_held() &&
                        ev->code >= BTN_DPAD_UP && ev->code <= BTN_DPAD_RIGHT) {
                        /* native d-pad: forward to the virtual keyboard instead of
                         * turning it into an injected arrow key */
                        pad_dpad_key(ev->code, ev->value);
                        continue;
                    }"""
if old_key not in s:
    print("MISS key fwd"); sys.exit(1)
s = s.replace(old_key, "                    /* d-pad 键同样交给 App 处理 */", 1)

# 2) 新命令 H <dir> [hold]：把方向写到虚拟手柄的 HAT 上（系统会翻成 DPAD_*）
anchor = "        case 'N': {"
if anchor not in s:
    print("MISS N"); sys.exit(1)
cmd = '''        case 'H': {
            /* H <dir> [hold]  dir: 1=上 2=下 3=左 4=右
             * 由 App 决策后回写到虚拟手柄的 HAT：系统 InputReader 会把它变成
             * DPAD_* 键，应用和游戏都能当成「真正的 d-pad」。 */
            int dir = 0, hold = 0;
            if (sscanf(line, "%d %d", &dir, &hold) < 1) { out("ERR H"); break; }
            int wantX = (dir == 3) ? -1 : (dir == 4 ? 1 : 0);
            int wantY = (dir == 1) ? -1 : (dir == 2 ? 1 : 0);
            if (g_hat_x != wantX) { g_hat_x = wantX; }
            if (g_hat_y != wantY) { g_hat_y = wantY; }
            if (g_pad >= 0) {
                ev_emit(g_pad, EV_ABS, ABS_HAT0X, wantX);
                ev_emit(g_pad, EV_ABS, ABS_HAT0Y, wantY);
                ev_syn(g_pad);
            }
            if (!hold) {
                usleep(45 * 1000);
                if (g_pad >= 0) {
                    ev_emit(g_pad, EV_ABS, ABS_HAT0X, 0);
                    ev_emit(g_pad, EV_ABS, ABS_HAT0Y, 0);
                    ev_syn(g_pad);
                }
                g_hat_x = 0;
                g_hat_y = 0;
            }
            out("HAT %d hold=%d", dir, hold);
            break;
        }
'''
s = s.replace(anchor, cmd + anchor, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper ok")

# ---------------- RootInput ----------------
r = io.open(R, encoding="utf-8").read()
r = r.replace("    fun pointKey(displayId: Int, keyCode: Int) = send(\"D $displayId $keyCode\")",
"""    fun pointKey(displayId: Int, keyCode: Int) = send("D $displayId $keyCode")

    /** 方向键走虚拟手柄 HAT（系统会翻成 DPAD_*），dir: 1上 2下 3左 4右 */
    fun hat(dir: Int, hold: Boolean = false) = send("H $dir " + if (hold) 1 else 0)""", 1)
io.open(R, "w", encoding="utf-8", newline="\n").write(r)
print("rootinput ok")

# ---------------- ActionRouter ----------------
a = io.open(A, encoding="utf-8").read()
a = a.replace("""                root.pointKey(display, code)
                host.onArrowKey()""",
"""                // 软件在虚拟控制器层之上：方向键不直接注入 keyevent，
                // 而是回写虚拟手柄的 HAT，系统再翻成 DPAD_*（应用/游戏都是原生 d-pad）
                root.hat(
                    when (action) {
                        Action.ARROW_UP -> 1
                        Action.ARROW_DOWN -> 2
                        Action.ARROW_LEFT -> 3
                        else -> 4
                    },
                )
                host.onArrowKey()""", 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(a)
print("router ok")

# ---------------- EngineService: 不再切换 I ----------------
e = io.open(E, encoding="utf-8").read()
start = e.index("        // keep the helper's d-pad forwarding in sync with the current mapping:")
end = e.index("        }", e.index("root.dpadNative(", start)) + len("        }")
block = e[start:end]
print("block len", len(block))
e = e[:start] + """        // d-pad 统一走 App（软件在虚拟控制器层之上），助手不再自己转发，
        // 这样「普通方向键」和「X+方向键」只是 App 里的两种分支，互不抢占。
""" + e[end:]
io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine ok")
