import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
cp = os.path.join(root, "app", "src", "main", "assets", "gpminput.c")
c = io.open(cp, encoding="utf-8").read()

# 1) remember the injector pid
if "static pid_t g_inject_pid" not in c:
    c = c.replace("static int g_inject_fd = -1;",
                  "static int g_inject_fd = -1;\nstatic pid_t g_inject_pid = -1;", 1)

# 2) record it on spawn
c = c.replace("    g_inject_fd = pfd[1];\n    usleep(1800 * 1000);",
              "    g_inject_fd = pfd[1];\n    g_inject_pid = pid;\n    usleep(1800 * 1000);", 1)

# 3) watchdog: respawn the injector when it dies
watchdog = """
// keeps the scroll injector alive: respawns it if the child exits or the pipe
// breaks (the app keeps talking to us, so the injector must not be a single
// point of failure)
static void check_injector(void) {
    if (g_inject_pid > 0) {
        int st = 0;
        pid_t r = waitpid(g_inject_pid, &st, WNOHANG);
        if (r == g_inject_pid) {
            out("INJECTOR died (st=%d), respawning", st);
            if (g_inject_fd >= 0) { close(g_inject_fd); g_inject_fd = -1; }
            g_inject_pid = -1;
            spawn_injector();
        }
    } else if (g_inject_fd < 0) {
        spawn_injector();
    }
}

"""
if "static void check_injector(void)" not in c:
    c = c.replace("static void injector_scroll(", watchdog + "static void injector_scroll(", 1)

# 4) pipe write failure -> treat as dead
c = c.replace("""static void injector_scroll(float x, float y, float dy, float dx, int disp) {
    if (g_inject_fd < 0) return;""",
              """static void injector_scroll(float x, float y, float dy, float dx, int disp) {
    if (g_inject_fd < 0) { check_injector(); return; }""", 1)
c = c.replace("""    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }""",
              """    if (n > 0) {
        ssize_t r = write(g_inject_fd, buf, (size_t)n);
        if (r < 0 && (errno == EPIPE || errno == EBADF)) {
            close(g_inject_fd);
            g_inject_fd = -1;
            g_inject_pid = -1;
            spawn_injector();
        }
    }""", 1)

# 5) call the watchdog from the poll loop (every rescan tick, ~2s)
c = c.replace("""        if (time(NULL) - last_scan >= 2) {
            last_scan = time(NULL);
            scan_new_devices();""",
              """        if (time(NULL) - last_scan >= 2) {
            last_scan = time(NULL);
            check_injector();
            scan_new_devices();""", 1)

io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("helper watchdog added")

# 6) module service.sh: explicit supervision of the helper process
mod = os.path.join(root, "ksu-module")
sp = os.path.join(mod, "service.sh")
sh = """#!/system/bin/sh
# KernelSU / Magisk late-start service: supervise the Gamepad Mouse helper.
# - keeps /data/adb/gpm/{gpminput,inject.dex} in sync with the module
# - restarts the helper if it dies (the helper in turn supervises the injector)
MODDIR=${0%/*}
PKG=com.dennis.gamepadmouse
SOCKDIR=/data/data/$PKG/files
SOCK=$SOCKDIR/gpm.sock
BIN=$MODDIR/gpminput
DEX=$MODDIR/inject.dex

mkdir -p /data/adb/gpm
[ -f "$DEX" ] && cp -f "$DEX" /data/adb/gpm/inject.dex && chmod 644 /data/adb/gpm/inject.dex
[ -f "$BIN" ] && cp -f "$BIN" /data/adb/gpm/gpminput && chmod 755 /data/adb/gpm/gpminput

# wait for the app data dir (first launch can be late) - max 5 min
i=0
while [ ! -d "/data/data/$PKG" ] && [ $i -lt 300 ]; do
    sleep 1
    i=$((i+1))
done
mkdir -p "$SOCKDIR" 2>/dev/null

while true; do
    if [ ! -x /data/adb/gpm/gpminput ] || [ ! -d "$SOCKDIR" ]; then
        sleep 3
        continue
    fi
    # blocking run: when it exits we loop and restart it
    /data/adb/gpm/gpminput --socket "$SOCK" >>/data/local/tmp/gpm-module.log 2>&1
    echo "helper exited, restarting" >>/data/local/tmp/gpm-module.log
    sleep 2
done
"""
io.open(sp, "w", encoding="utf-8", newline="\n").write(sh)
print("service.sh supervises the helper")
