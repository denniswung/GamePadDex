import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
marker = "/* 虚拟触摸屏：Android 用多点协议 B"
if "static void ev_emit(int fd, int type, int code, int val);" not in s:
    s = s.replace(marker, "static void ev_emit(int fd, int type, int code, int val);\nstatic void ev_syn(int fd);\n\n" + marker, 1)
    io.open(H, "w", encoding="utf-8", newline="\n").write(s)
    print("declared")
else:
    print("already")
