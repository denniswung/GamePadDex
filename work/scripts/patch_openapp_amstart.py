import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

s = io.open(H, encoding="utf-8").read()
if "OPEN_APP" not in s:
    anchor = "        case 'q': {"
    add = """        case 'w': {
            /* w <pkg> : 启动目标应用（后台服务自己 startActivity 会被系统拦，
             * 走 root 的 am start 才可靠） */
            char pkg3[192] = {0};
            if (sscanf(line, "%191s", pkg3) == 1 && pkg3[0]) {
                char cmd4[400];
                snprintf(cmd4, sizeof(cmd4),
                         "/system/bin/am start -a android.intent.action.MAIN "
                         "-c android.intent.category.LAUNCHER -p %s >/dev/null 2>&1", pkg3);
                pid_t ch = fork();
                if (ch == 0) {
                    int rc = system(cmd4);
                    out("OPEN_APP %s rc=%d", pkg3, rc);
                    _exit(0);
                }
                out("OPEN_APP %s async", pkg3);
            }
            break;
        }
"""
    idx = s.index(anchor)
    s = s[:idx] + add + s[idx:]
    io.open(H, "w", encoding="utf-8", newline="\n").write(s)
    print("helper ok")
else:
    print("helper already")

r = io.open(R, encoding="utf-8").read()
if "fun openApp" not in r:
    r = r.replace('    fun forceStopTop() = send("f")',
                  '    fun forceStopTop() = send("f")\n\n    /** 启动目标应用（走 root 的 am start，绕过后台启动限制） */\n    fun openApp(pkg: String) = send("w $pkg")', 1)
    io.open(R, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

e = io.open(E, encoding="utf-8").read()
if "root.openApp(pkg)" not in e:
    e = e.replace('''            i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(i)''',
'''            i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            // 后台服务直接 startActivity 会被系统拦截：优先让 root 助手 am start
            if (root.helperReady) root.openApp(pkg)
            else startActivity(i)''', 1)
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
    print("engine ok")
