import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
old = '    if (argc >= 3 && strcmp(argv[1], "--socket") == 0) setup_socket(argv[2]);'
assert old in c, "socket start not found"
new = """    if (argc >= 3 && strcmp(argv[1], "--socket") == 0) {
        if (!take_single_instance_lock()) {
            fprintf(stderr, "another helper holds the lock - exiting\\n");
            return 0;
        }
        setup_socket(argv[2]);
    }"""
c = c.replace(old, new, 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("main guarded")

# ---------- app: wait for the module helper before spawning our own ----------
rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
old2 = """                if (!trySocketTransport()) launchProcess()"""
assert old2 in r, "start block not found"
new2 = """                var ok = trySocketTransport()
                if (!ok && File("/data/adb/modules/gpm_dex").exists()) {
                    // the KernelSU module supervises the helper: never spawn a
                    // second instance, just wait for its socket
                    for (i in 0 until 12) {
                        Thread.sleep(500)
                        if (trySocketTransport()) { ok = true; break }
                    }
                }
                if (!ok) launchProcess()"""
r = r.replace(old2, new2, 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("app waits for the module helper")