import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
T = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v147_checklist.sh"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# diagnostics are not capabilities
rep(H, '    out("CAP apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);',
       '    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);',
    "apex info")
rep(H, '        out("CAP uia rc=%d bytes=%ld", rc, sz);',
       '        out("INFO uia rc=%d bytes=%ld", rc, sz);', "uia info")

rep(T, "grep ' 0$' | grep -vE 'focus_rect|devices'", "grep ' 0$' | grep -vE 'focus_rect'", "test ignore")
io.open(T, "w", encoding="utf-8", newline="\n").write(io.open(T, encoding="utf-8").read())
print("done")
