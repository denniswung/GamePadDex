import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()

# 1) grab request: tell how many devices the helper currently holds
old = """            scan_new_devices();
            grab_all();
            break;"""
assert old in s, "G branch not found"
new = """            out("GRAB_REQ ndev=%d grabmode=%d", g_ndev, g_grab_mode);
            scan_new_devices();
            out("GRAB_AFTER_SCAN ndev=%d", g_ndev);
            grab_all();
            break;"""
s = s.replace(old, new, 1)

# 2) device removal: log why
old2 = """            if (pfd[1 + i].revents & (POLLHUP | POLLERR | POLLNVAL)) {
                remove_dev(i);"""
assert old2 in s
new2 = """            if (pfd[1 + i].revents & (POLLHUP | POLLERR | POLLNVAL)) {
                out("GONE_EVT %s revents=%d", g_devs[i].path, pfd[1 + i].revents);
                remove_dev(i);"""
s = s.replace(old2, new2, 1)

old3 = """                if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) continue;
                remove_dev(i);"""
assert old3 in s
new3 = """                if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) continue;
                out("GONE_READ %s errno=%d (%s)", g_devs[i].path, errno, strerror(errno));
                remove_dev(i);"""
s = s.replace(old3, new3, 1)

old4 = """            if (rd == 0) {
                remove_dev(i);"""
assert old4 in s
new4 = """            if (rd == 0) {
                out("GONE_EOF %s", g_devs[i].path);
                remove_dev(i);"""
s = s.replace(old4, new4, 1)

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("diagnostics added")