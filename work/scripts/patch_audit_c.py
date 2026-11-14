import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 1) O 命令解析第 5 个参数（居中增益）
rep("""        case 'O': {
            int w, h, park = 0, rot = 0;
            int n = sscanf(line, "%d %d %d %d", &w, &h, &park, &rot);
            if (n >= 2) cmd_center(w, h, park, rot);
            break;
        }""",
    """        case 'O': {
            int w, h, park = 0, rot = 0;
            double gain = 0;
            int n = sscanf(line, "%d %d %d %d %lf", &w, &h, &park, &rot, &gain);
            if (n >= 5 && gain > 0.5 && gain < 20.0) g_center_gain = gain;
            if (n >= 2) cmd_center(w, h, park, rot);
            break;
        }""", "O-gain")

# 2) GONE 带名字
rep('        out("GONE %d", g_devs[i].id);',
    '        out("GONE %d %s", g_devs[i].id, g_devs[i].name);', "GONE-name")

# 3) AXMAP 刷屏日志关掉
rep('                    out("AXMAP raw=%d android=%d rx=%d ry=%d name=%s",',
    '                    if (0) out("AXMAP raw=%d android=%d rx=%d ry=%d name=%s",', "AXMAP")

# 4) 扳机归一化（有右摇杆时 Z/RZ 是扳机，0..1）
rep("""        case ABS_X: case ABS_Y: case ABS_Z: case ABS_RX: case ABS_RY: case ABS_RZ:
            if (hi <= lo) return 0.0f;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;""",
    """        case ABS_Z: case ABS_RZ:
            /* 有右摇杆的手柄：Z/RZ 是扳机，按 0..1 归一（否则要按到 75% 才触发） */
            if (d->has_abs[ABS_RX] || d->has_abs[ABS_RY]) {
                if (hi <= lo) return 0.0f;
                return (float)(value - lo) / (float)(hi - lo);
            }
            if (hi <= lo) return 0.0f;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;
        case ABS_X: case ABS_Y: case ABS_RX: case ABS_RY:
            if (hi <= lo) return 0.0f;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;""", "trigger")

# 5) 修正 F1-F4 的错误映射，并补全 常用键/字母/数字
rep("""        case 131: return 62;   /* F4 */""",
    """        case 131: return 59;   /* F1 */
        case 132: return 60;   /* F2 */
        case 133: return 61;   /* F3 */
        case 134: return 62;   /* F4 */""", "F1-F4")

rep("""        case 88:  return 165;  /* MEDIA_PREVIOUS */
        default:  return -1;""",
    """        case 88:  return 165;  /* MEDIA_PREVIOUS */
        /* 常用字符 / 功能键（自定义快捷键用） */
        case 62:  return 57;   /* SPACE */
        case 66:  return 28;   /* ENTER */
        case 160: return 28;   /* NUMPAD_ENTER */
        case 111: return 1;    /* ESCAPE */
        case 112: return 111;  /* FORWARD_DEL */
        case 19:  return 103;  /* DPAD_UP */
        case 20:  return 108;  /* DPAD_DOWN */
        case 21:  return 105;  /* DPAD_LEFT */
        case 22:  return 106;  /* DPAD_RIGHT */
        case 123: return 107;  /* MOVE_END */
        case 92:  return 104;  /* PAGE_UP */
        case 93:  return 109;  /* PAGE_DOWN */
        case 117: return 125;  /* META_LEFT (win) */
        case 118: return 126;  /* META_RIGHT */
        case 7:   return 2;    /* 0 */
        case 8:   return 3;    /* 1 */
        case 9:   return 4;    /* 2 */
        case 10:  return 5;    /* 3 */
        case 11:  return 6;    /* 4 */
        case 12:  return 7;    /* 5 */
        case 13:  return 8;    /* 6 */
        case 14:  return 9;    /* 7 */
        case 15:  return 10;   /* 8 */
        case 16:  return 11;   /* 9 */
        case 34:  return 33;   /* F */
        case 35:  return 34;   /* G */
        case 36:  return 35;   /* H */
        case 37:  return 23;   /* I */
        case 38:  return 36;   /* J */
        case 39:  return 37;   /* K */
        case 40:  return 38;   /* L */
        case 41:  return 50;   /* M */
        case 42:  return 49;   /* N */
        case 43:  return 24;   /* O */
        case 44:  return 25;   /* P */
        case 45:  return 16;   /* Q */
        case 46:  return 19;   /* R */
        case 47:  return 31;   /* S */
        case 48:  return 20;   /* T */
        case 49:  return 22;   /* U */
        case 50:  return 47;   /* V */
        case 51:  return 17;   /* W */
        case 52:  return 45;   /* X */
        case 53:  return 21;   /* Y */
        case 54:  return 44;   /* Z */
        case 135: return 63;   /* F5 */
        case 136: return 64;   /* F6 */
        case 137: return 65;   /* F7 */
        case 138: return 66;   /* F8 */
        case 139: return 67;   /* F9 */
        case 140: return 68;   /* F10 */
        case 141: return 87;   /* F11 */
        case 142: return 88;   /* F12 */
        default:  return -1;""", "keymap")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
