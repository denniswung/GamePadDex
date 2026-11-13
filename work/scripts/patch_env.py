import io
root = r"E:\Dennis\GamePadDex复刻\project"

# ---- C: start app_process through a shell that exports the runtime env ----
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
old = """        execl("/system/bin/app_process", "app_process",
              "-Djava.class.path=/data/adb/gpm/inject.dex",
              "/system/bin", "ScrollInject", "--stdio", (char *)NULL);"""
assert old in c, "app_process exec not found"
new = """        /* service.sh starts us with a minimal environment: app_process needs
           ANDROID_ROOT / LD_LIBRARY_PATH or the linker cannot find its libs */
        execl("/system/bin/sh", "sh", "-c",
              "export ANDROID_ROOT=/system; export ANDROID_DATA=/data; "
              "export LD_LIBRARY_PATH=/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64; "
              "exec /system/bin/app_process -Djava.class.path=/data/adb/gpm/inject.dex "
              "/system/bin ScrollInject --stdio",
              (char *)NULL);"""
c = c.replace(old, new, 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("helper: injector gets a proper env")

# ---- module service.sh: export the same env for the helper itself ----
sp = root + r"\ksu-module\service.sh"
s = io.open(sp, encoding="utf-8").read()
if "LD_LIBRARY_PATH" not in s:
    s = s.replace("mkdir -p /data/adb/gpm",
"""# app_process (used by the scroll injector) needs the runtime environment
export ANDROID_ROOT=/system
export ANDROID_DATA=/data
export LD_LIBRARY_PATH=/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64

mkdir -p /data/adb/gpm""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("service.sh exports the env")