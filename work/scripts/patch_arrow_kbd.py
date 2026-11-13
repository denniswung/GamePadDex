import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

start = s.index("        case 'A': {")
end = s.index("        case 'N': {", start)
new = '''        case 'A': {
            /* A <dir> [hold]  dir: 1上 2下 3左 4右
             * 由 App 决策后回写方向：走虚拟键盘的箭头键（与旧的原生转发等价，
             * 系统会把它当成 DPAD_*），没有虚拟键盘时退回 `input keyevent`。 */
            int dir = 0, hold = 0;
            if (sscanf(line, "%d %d", &dir, &hold) < 1) { out("ERR A"); break; }
            int key = (dir == 1) ? 103 : (dir == 2) ? 108 : (dir == 3) ? 105 : 106;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, key, 1);
                ev_syn(g_kbd);
                if (hold) {
                    out("ARROW %d hold", dir);
                    break;
                }
                usleep(45 * 1000);
                ev_emit(g_kbd, EV_KEY, key, 0);
                ev_syn(g_kbd);
                out("ARROW %d", dir);
                break;
            }
            if (hold) {
                /* 没有虚拟键盘：按住语义用 keyevent 实现不了，退化成一次点击 */
            }
            int kc = (dir == 1) ? 19 : (dir == 2) ? 20 : (dir == 3) ? 21 : 22;
            if (fork() == 0) {
                char c2[96];
                snprintf(c2, sizeof(c2), "/system/bin/input keyevent %d", kc);
                system(c2);
                _exit(0);
            }
            out("ARROW %d fallback=key", dir);
            break;
        }
'''
s = s[:start] + new + s[end:]
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
