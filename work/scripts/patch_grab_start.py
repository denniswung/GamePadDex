import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
old = """        spawn_injector();
        open_devices(0);
        out("READY");"""
assert old in s
new = """        spawn_injector();
        /* grab from the very first open: the app's "block stock input" default is
           on, and a grab later on only succeeds if nobody else took the device */
        g_grab_mode = 1;
        open_devices(1);
        out("READY");"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("helper grabs on startup")