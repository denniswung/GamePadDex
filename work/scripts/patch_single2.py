import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
old = "    unlink(path);\n    if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {"
assert old in s, "socket block not found"
new = """    if (socket_alive(path)) {
        fprintf(stderr, "another helper already listens on %s - exiting\\n", path);
        exit(0);   /* single instance: never fight over the EVIOCGRAB */
    }
    unlink(path);
    if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("guard inserted")