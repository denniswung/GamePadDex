import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

anchor = "        case 'C': {"
if anchor not in s:
    print("MISS anchor"); sys.exit(1)

helper = '''        case 'C': {
            /* C <display> <androidKeyCode> ... : 组合键（Ctrl+Plus 等）。
             * 不走 `input keycombination`：在 root 上下文里它返回 512（
             * 需要更宽的注入权限），而 uinput 键盘是进程内操作，稳定可用。 */
            char *p = line;
            char *end = NULL;
            int cd = (int)strtol(p, &end, 10);
            if (end == p || cd < 0) { out("ERR C display"); break; }
            p = end;
            int codes[8];
            int count = 0;
            while (*p && count < 8) {
                while (*p == ' ' || *p == '\\t') p++;
                if (!*p) break;
                char *e2 = NULL;
                long c = strtol(p, &e2, 10);
                if (e2 == p) break;
                codes[count++] = (int)c;
                p = e2;
            }
            if (count > 0) {
                int n = cmd_key_combo(codes, count);
                out("KCOMBO %d %d emitted=%d", cd, count, n);
            } else {
                out("ERR C no keys");
            }
            break;
        }
'''
start = s.index(anchor)
end = s.index("        case 'N': {", start)
s = s[:start] + helper + s[end:]

# 反向表 + 组合键实现（放在 cmd_alttab 之前，cmd_key 之后）
anchor2 = "/* Alt+Tab via the virtual keyboard"
if anchor2 not in s:
    print("MISS anchor2"); sys.exit(1)

impl = '''/* Android keycode -> Linux input code（只覆盖映射表里会用到的组合键） */
static int android_to_linux(int a) {
    switch (a) {
        case 113: return 29;   /* CTRL_LEFT */
        case 114: return 97;   /* CTRL_RIGHT */
        case 57:  return 56;   /* ALT_LEFT */
        case 58:  return 100;  /* ALT_RIGHT */
        case 59:  return 42;   /* SHIFT_LEFT */
        case 60:  return 54;   /* SHIFT_RIGHT */
        case 61:  return 15;   /* TAB */
        case 131: return 62;   /* F4 */
        case 69:  return 12;   /* MINUS */
        case 81:  return 13;   /* PLUS */
        case 67:  return 14;   /* DEL */
        case 29:  return 30;   /* A */
        case 30:  return 48;   /* B */
        case 31:  return 46;   /* C */
        case 32:  return 32;   /* D */
        case 33:  return 18;   /* E */
        case 122: return 102;  /* HOME */
        case 4:   return 158;  /* BACK */
        case 187: return 125;  /* APP_SWITCH */
        case 3:   return 102;  /* HOME */
        case 24:  return 115;  /* VOLUME_UP */
        case 25:  return 114;  /* VOLUME_DOWN */
        case 164: return 113;  /* MUTE */
        case 85:  return 164;  /* MEDIA_PLAY_PAUSE */
        case 87:  return 163;  /* MEDIA_NEXT */
        case 88:  return 165;  /* MEDIA_PREVIOUS */
        default:  return -1;
    }
}

/* 依次按下，再逆序释放：Ctrl+Minus 这类组合才会被应用当成“按住组合” */
static int cmd_key_combo(const int *androidCodes, int count) {
    if (g_kbd < 0) return 0;
    int linux[8];
    int n = 0;
    for (int i = 0; i < count && i < 8; i++) {
        int l = android_to_linux(androidCodes[i]);
        if (l >= 0) linux[n++] = l;
    }
    if (n == 0) return 0;
    for (int i = 0; i < n; i++) {
        ev_emit(g_kbd, EV_KEY, linux[i], 1);
        ev_syn(g_kbd);
        usleep(8 * 1000);
    }
    usleep(30 * 1000);
    for (int i = n - 1; i >= 0; i--) {
        ev_emit(g_kbd, EV_KEY, linux[i], 0);
        ev_syn(g_kbd);
        usleep(8 * 1000);
    }
    return n;
}

'''
s = s.replace(anchor2, impl + anchor2, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
