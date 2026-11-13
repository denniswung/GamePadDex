import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
old = "if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {"
if "already running" not in s:
    s = s.replace(old, """if (sockpath && socket_alive(sockpath)) {
        fprintf(stderr, "another helper already listens on %s - exiting\\n", sockpath);
        return 0;   /* single instance: never fight over the EVIOCGRAB */
    }
    if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("single-instance guard inserted")