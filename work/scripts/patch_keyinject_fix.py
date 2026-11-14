import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
fails = []

# ---------- helper：D 命令改走 uinput 键盘（input 在 root 域 rc=512，注入无效） ----------
h = io.open(H, encoding="utf-8").read()
old_d = '''        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) {
                /* async: `input keyevent` takes ~100 ms */
                if (fork() == 0) {
                    char cmd[160];
                    snprintf(cmd, sizeof(cmd), "/system/bin/input -d %d keyevent %d", kd, kc);
                    int rc = system(cmd);
                    out("KEYON %d %d rc=%d", kd, kc, rc);
                    _exit(0);
                }
            }
            break;
        }'''
new_d = '''        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) {
                /* 优先用我们自己的虚拟键盘注入（内核级，稳定）：
                 * `input keyevent` 在 ksu 域里返回 512（exit code 2），事件根本进不去，
                 * HOME/BACK/音量/静音/媒体键全都是"日志有、实际没反应"。 */
                int lc = android_to_linux(kc);
                if (g_kbd >= 0 && lc >= 0) {
                    ev_emit(g_kbd, EV_KEY, lc, 1);
                    ev_syn(g_kbd);
                    usleep(8 * 1000);
                    ev_emit(g_kbd, EV_KEY, lc, 0);
                    ev_syn(g_kbd);
                    out("KEYUIN %d %d lcode=%d", kd, kc, lc);
                } else {
                    /* 没映射的键才退回 input（子进程里跑，避免卡主循环） */
                    if (fork() == 0) {
                        char cmd[160];
                        snprintf(cmd, sizeof(cmd), "/system/bin/input -d %d keyevent %d", kd, kc);
                        int rc = system(cmd);
                        out("KEYON %d %d rc=%d (unmapped)", kd, kc, rc);
                        _exit(0);
                    }
                }
            }
            break;
        }'''
if old_d not in h:
    fails.append("D-cmd")
else:
    h = h.replace(old_d, new_d, 1)

# 补 android_to_linux：SYSRQ / DPAD_CENTER / MENU
old_map = "        case 123: return 107;  /* MOVE_END */"
new_map = """        case 123: return 107;  /* MOVE_END */
        case 120: return 99;   /* SYSRQ (截图) */
        case 23:  return 352;  /* DPAD_CENTER -> KEY_OK */
        case 82:  return 139;  /* MENU */"""
if old_map not in h:
    fails.append("keymap-add")
else:
    h = h.replace(old_map, new_map, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(h)

# ---------- ActionRouter：横向滚动方向与标签一致 ----------
a = io.open(A, encoding="utf-8").read()
old_w = """            Action.WHEEL_LEFT -> fireSwipeOnce(1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(-1, 60)"""
new_w = """            // 手指方向 = 动作名字：向左滚动 = 手指往左（界面向左翻）
            Action.WHEEL_LEFT -> fireSwipeOnce(-1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(1, 60)"""
if old_w not in a:
    fails.append("wheel")
else:
    a = a.replace(old_w, new_w, 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(a)

print("FAILS:", fails if fails else "none")
