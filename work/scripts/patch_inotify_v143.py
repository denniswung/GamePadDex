import io, sys
p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()
if "inotify" in s:
    print("already"); sys.exit(0)

s = s.replace("#include <dirent.h>", "#include <dirent.h>\n#include <sys/inotify.h>", 1)
s = s.replace("static time_t g_last_wake_at = 0;", "static time_t g_last_wake_at = 0;\nstatic int g_ino_fd = -1;", 1)

s = s.replace("""    if (g_mouse >= 0 || g_kbd >= 0) usleep(150 * 1000);

    char linebuf[256];""",
"""    if (g_mouse >= 0 || g_kbd >= 0) usleep(150 * 1000);
    g_ino_fd = inotify_init1(IN_NONBLOCK);
    if (g_ino_fd >= 0) {
        inotify_add_watch(g_ino_fd, "/dev/input", IN_CREATE | IN_ATTRIB | IN_MOVED_TO);
    }

    char linebuf[256];""", 1)

s = s.replace("    struct pollfd pfd[1 + MAX_DEVS + 1];", "    struct pollfd pfd[1 + MAX_DEVS + 2];", 1)

s = s.replace("""        int rc = poll(pfd, n, 400);""",
"""        int ino_idx = -1;
        if (g_ino_fd >= 0) {
            ino_idx = n;
            pfd[n].fd = g_ino_fd;
            pfd[n].events = POLLIN;
            n++;
        }
        int rc = poll(pfd, n, 400);""", 1)

s = s.replace("""        if (pfd[0].revents & (POLLIN | POLLHUP)) {""",
"""        if (ino_idx >= 0 && (pfd[ino_idx].revents & POLLIN)) {
            char ib[512];
            while (read(g_ino_fd, ib, sizeof(ib)) > 0) { }
            scan_new_devices();
        }

        if (pfd[0].revents & (POLLIN | POLLHUP)) {""", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok inotify")
