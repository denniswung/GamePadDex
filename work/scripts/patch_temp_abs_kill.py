import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

if "ABS_MOVE" not in s:
    anchor = "        case 'g': {"
    add = """        case 'q': {
            /* 试验：用 `input mouse motionevent MOVE x y` 绝对定位指针 */
            int ax = 0, ay = 0;
            if (sscanf(line, "%d %d", &ax, &ay) == 2) {
                char c2[160];
                snprintf(c2, sizeof(c2), "/system/bin/input mouse motionevent MOVE %d %d", ax, ay);
                int rc = system(c2);
                out("ABS_MOVE %d %d rc=%d", ax, ay, rc);
            }
            break;
        }
        case 'k': {
            /* 试验：直接从本域执行 am force-stop */
            char pkg2[192] = {0};
            if (sscanf(line, "%191s", pkg2) == 1 && pkg2[0]) {
                char c3[320];
                snprintf(c3, sizeof(c3), "/system/bin/am force-stop %s", pkg2);
                int rc = system(c3);
                out("KILLTEST %s rc=%d", pkg2, rc);
            }
            break;
        }
"""
    idx = s.index(anchor)
    s = s[:idx] + add + s[idx:]

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
