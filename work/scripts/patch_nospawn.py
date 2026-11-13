import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
s = io.open(p, encoding="utf-8").read()
old = """                var ok = trySocketTransport()
                if (!ok && File("/data/adb/modules/gpm_dex").exists()) {
                    // the KernelSU module supervises the helper: never spawn a
                    // second instance, just wait for its socket
                    for (i in 0 until 12) {
                        Thread.sleep(500)
                        if (trySocketTransport()) { ok = true; break }
                    }
                }
                if (!ok) launchProcess()"""
assert old in s, "start block"
new = """                var ok = trySocketTransport()
                if (!ok && File("/data/adb/modules/gpm_dex").exists()) {
                    // the KernelSU module owns the helper: never spawn a second
                    // instance (the two would fight over the EVIOCGRAB), just wait
                    while (!ok && running.get()) {
                        for (i in 0 until 10) {
                            Thread.sleep(500)
                            if (!running.get()) break
                            if (trySocketTransport()) { ok = true; break }
                        }
                    }
                    return@Thread
                }
                if (!ok) launchProcess()"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("app never spawns when the module exists")