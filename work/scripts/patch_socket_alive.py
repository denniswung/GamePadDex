import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
if "socket_alive" not in s:
    fn = r"""
// true when another helper is already listening on this socket (only one helper
// may hold the EVIOCGRAB, otherwise input lands in a helper nobody talks to)
static int socket_alive(const char *path) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return 0;
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    int r = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    close(fd);
    return r == 0;
}

"""
    s = s.replace("static void spawn_injector(void) {", fn + "static void spawn_injector(void) {", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("socket_alive added")