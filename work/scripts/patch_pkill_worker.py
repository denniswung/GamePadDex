import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
old = """    unlink(FOCUS_DONE);
    unlink(FOCUS_REQ);
    /* a single detached worker"""
new = """    unlink(FOCUS_DONE);
    unlink(FOCUS_REQ);
    /* drop a stale worker that still runs an older copy of the script */
    system("/system/bin/pkill -f " FOCUS_SHELL " >/dev/null 2>&1");
    /* a single detached worker"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
