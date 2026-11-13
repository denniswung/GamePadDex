import io
root = r"E:\Dennis\GamePadDex复刻\project"

# ---------- helper: flock single instance ----------
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
if "helper.lock" not in c:
    c = c.replace("#include <sys/stat.h>", "#include <sys/stat.h>\n#include <sys/file.h>", 1)
    fn = r"""
// hard single-instance guard: only one helper may hold the EVIOCGRAB
static int g_lock_fd = -1;
static int take_single_instance_lock(void) {
    g_lock_fd = open("/data/adb/gpm/helper.lock", O_CREAT | O_RDWR, 0666);
    if (g_lock_fd < 0) return 1;            /* cannot lock: better run than not */
    if (flock(g_lock_fd, LOCK_EX | LOCK_NB) != 0) return 0;
    return 1;
}

"""
    c = c.replace("static int socket_alive(const char *path) {", fn + "static int socket_alive(const char *path) {", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper flock added")