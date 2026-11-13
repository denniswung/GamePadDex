import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
old = """            if (pkg[0]) {
                char cmd[320];
                snprintf(cmd, sizeof(cmd), "/system/bin/sh -c \\"PATH=/system/bin cmd activity force-stop %s\\"", pkg);
                int rc = system(cmd);
                out("FORCE_STOP %s rc=%d", pkg, rc);
            } else {"""
new = """            if (pkg[0]) {
                char cmd[320];
                snprintf(cmd, sizeof(cmd), "/system/bin/sh -c \\"PATH=/system/bin cmd activity force-stop %s\\"", pkg);
                int rc = system(cmd);
                out("FORCE_STOP %s rc=%d", pkg, rc);
                /* the KSU SELinux domain may deny binder calls from `cmd`:
                   kill the app's processes directly as a fallback */
                if (rc != 0) {
                    char kc[320];
                    snprintf(kc, sizeof(kc), "/system/bin/sh -c \\"for p in $(/system/bin/pidof %s); do /system/bin/kill -9 $p; done\\"", pkg);
                    rc = system(kc);
                    out("FORCE_KILL %s rc=%d", pkg, rc);
                }
            } else {"""
if old not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old, new)
io.open(h, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
