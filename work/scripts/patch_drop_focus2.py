import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
# g_last_input_ms was only used for the deferred focus dump
s = s.replace("        g_last_input_ms = now_ms();\n", "")
s = s.replace("static long long g_last_input_ms = 0;\n", "")
# keep the declaration comment tidy if it survived
s = s.replace("/* the accessibility dump briefly pauses the foreground app, so it is deferred\n"
              " * until the input has been quiet for a moment */\n"
              "static int g_focus_want = 0;\n", "")
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
