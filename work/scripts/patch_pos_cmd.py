import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
if "case 'P'" not in s:
    anchor = "        case 'h': {"
    add = """        case 'P': {
            /* 调试：打印助手读到的指针位置 */
            int px = -1, py = -1;
            read_pointer(&px, &py);
            out("POS %d %d", px, py);
            break;
        }
"""
    s = s.replace(anchor, add + anchor, 1)
    io.open(H, "w", encoding="utf-8", newline="\n").write(s)
    print("ok")
else:
    print("already")
