import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()

# also append every helper message to a file so failures survive the socket
old = """    // write() directly, ignore partial writes for these tiny lines
    ssize_t r = write(STDOUT_FILENO, buf, n);
    (void)r;
}"""
assert old in s, "out() body not found"
new = """    // write() directly, ignore partial writes for these tiny lines
    ssize_t r = write(STDOUT_FILENO, buf, n);
    (void)r;
    static int logfd = -2;
    if (logfd == -2) {
        mkdir("/data/adb", 0755);
        mkdir("/data/adb/gpm", 0755);
        logfd = open("/data/adb/gpm/helper.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
    }
    if (logfd >= 0) {
        ssize_t w = write(logfd, buf, n);
        (void)w;
    }
}"""
s = s.replace(old, new, 1)

# make the grab failure reason explicit
old2 = """            if (ioctl(fd, EVIOCGRAB, 1) < 0) {
                out("ERR grab %s (%s) failed: %s", path, d->name, strerror(errno));"""
assert old2 in s
new2 = """            if (ioctl(fd, EVIOCGRAB, 1) < 0) {
                out("ERR grab %s (%s) failed: %s", path, d->name, strerror(errno));"""
s = s.replace(old2, new2, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("helper messages are also written to /data/adb/gpm/helper.log")