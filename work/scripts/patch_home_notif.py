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


# HOME 必须用 KEY_HOMEPAGE(172)：KEY_HOME(102) 在 Android 上不触发回主屏
rep("        case 122: return 102;  /* HOME */", "        case 122: return 172;  /* HOME -> KEY_HOMEPAGE */", "home122")
rep("        case 3:   return 102;  /* HOME */", "        case 3:   return 172;  /* HOME -> KEY_HOMEPAGE */", "home3")

# 通知栏：input 在本域不可用（rc=512），改走 uinput KEY_NOTIFICATION_CENTER(444)
rep('''        case 'N': {
            int rc = system("/system/bin/cmd statusbar expand-notifications");
            out("NOTIF rc=%d", rc);
            break;
        }''',
    '''        case 'N': {
            /* cmd statusbar 在这个 SELinux 域里注入不了（rc=512），
             * 改走虚拟键盘的 KEY_NOTIFICATION_CENTER(444) → 系统映射成通知栏。 */
            int ok = 0;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, 444, 1);
                ev_syn(g_kbd);
                usleep(40 * 1000);
                ev_emit(g_kbd, EV_KEY, 444, 0);
                ev_syn(g_kbd);
                ok = 1;
            }
            out("NOTIF uinput=%d", ok);
            break;
        }''', "notif")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
