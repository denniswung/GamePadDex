import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\assets\gpminput.c"
s = io.open(p, encoding="utf-8").read()
if "static void cmd_mouse_move(double dx, double dy);" not in s:
    s = s.replace("static void query_cursor_pos(int *ox, int *oy) {",
                  "static void cmd_mouse_move(double dx, double dy);\n\nstatic void query_cursor_pos(int *ox, int *oy) {", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("forward decl added")