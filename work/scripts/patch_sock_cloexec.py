import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# listening socket must not be inherited by spawned shells (they would keep the
# socket "alive" and the next helper would refuse to start)
old = "    int sfd = socket(AF_UNIX, SOCK_STREAM, 0);"
new = "    int sfd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);"
if old not in s:
    print("MISS sfd"); sys.exit(1)
s = s.replace(old, new, 1)

# the accepted client fd becomes stdin/stdout; also avoid leaking it into children
old2 = """            dup2(c, STDIN_FILENO);
            dup2(c, STDOUT_FILENO);
            close(c);"""
new2 = """            dup2(c, STDIN_FILENO);
            dup2(c, STDOUT_FILENO);
            close(c);
            /* the client channel must not leak into spawned shells */
            fcntl(STDIN_FILENO, F_SETFD, FD_CLOEXEC);"""
if old2 in s:
    s = s.replace(old2, new2, 1)
    print("ok client cloexec")

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
