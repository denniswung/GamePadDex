import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
if "static int kill_pkg_procs(const char *pkg) {" in s:
    print("already"); sys.exit(0)

anchor = "static void maybe_wake_on_connect(const char *name) {"
add = '''/* kill every process whose /proc/<pid>/cmdline starts with the package name
 * (the KSU SELinux domain cannot always use `cmd activity force-stop`) */
static int kill_pkg_procs(const char *pkg) {
    DIR *d = opendir("/proc");
    if (!d) return -1;
    int killed = 0;
    size_t plen = strlen(pkg);
    struct dirent *e;
    while ((e = readdir(d))) {
        if (e->d_name[0] < '0' || e->d_name[0] > '9') continue;
        char path[64], buf[512];
        snprintf(path, sizeof(path), "/proc/%s/cmdline", e->d_name);
        int fd = open(path, O_RDONLY);
        if (fd < 0) continue;
        ssize_t n = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        if (n <= 0) continue;
        buf[n] = 0;
        if (strncmp(buf, pkg, plen) == 0) {
            int pid = atoi(e->d_name);
            if (pid > 1) {
                kill(pid, SIGKILL);
                killed++;
            }
        }
    }
    closedir(d);
    return killed;
}

'''
if anchor not in s:
    print("MISS anchor"); sys.exit(1)
s = s.replace(anchor, add + anchor, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("restored")
