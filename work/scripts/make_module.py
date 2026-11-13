import io, os, shutil

root = r"E:\Dennis\GamePadDex复刻\project"
mod = os.path.join(root, "ksu-module")
os.makedirs(mod, exist_ok=True)

MODULE_PROP = """id=gpm_dex
name=Gamepad Mouse DeX Helper
version=v1.0
versionCode=1
author=Dennis
description=Starts the Gamepad Mouse root helper (EVIOCGRAB gamepad + uinput pointer) and the ACTION_SCROLL injector at boot, so the app can control the DeX desktop and block Samsung's built-in gamepad handling.
"""

SERVICE_SH = """#!/system/bin/sh
# KernelSU / Magisk late-start service: keep the Gamepad Mouse helper alive.
MODDIR=${0%/*}
PKG=com.dennis.gamepadmouse
SOCKDIR=/data/data/$PKG/files
SOCK=$SOCKDIR/gpm.sock
BIN=$MODDIR/gpminput
DEX=$MODDIR/inject.dex

# make the injector dex available where gpminput expects it
mkdir -p /data/adb/gpm
[ -f "$DEX" ] && cp -f "$DEX" /data/adb/gpm/inject.dex && chmod 644 /data/adb/gpm/inject.dex
[ -f "$BIN" ] && cp -f "$BIN" /data/adb/gpm/gpminput && chmod 755 /data/adb/gpm/gpminput

# wait for the app data dir (first launch can be late) - max 5 min
i=0
while [ ! -d "/data/data/$PKG" ] && [ $i -lt 300 ]; do
    sleep 1
    i=$((i+1))
done
mkdir -p "$SOCKDIR" 2>/dev/null

while true; do
    if [ -x /data/adb/gpm/gpminput ] && [ -d "$SOCKDIR" ]; then
        /data/adb/gpm/gpminput --socket "$SOCK" >/dev/null 2>&1
    fi
    sleep 3
done
"""

POST_FS_DATA = """#!/system/bin/sh
# nothing to do before /data is mounted
"""

with io.open(os.path.join(mod, "module.prop"), "w", encoding="utf-8", newline="\n") as f:
    f.write(MODULE_PROP)
with io.open(os.path.join(mod, "service.sh"), "w", encoding="utf-8", newline="\n") as f:
    f.write(SERVICE_SH)
with io.open(os.path.join(mod, "post-fs-data.sh"), "w", encoding="utf-8", newline="\n") as f:
    f.write(POST_FS_DATA)

# ship the current binaries with the module
for src, dst in ((os.path.join(root, "app", "src", "main", "assets", "gpminput"), "gpminput"),
                 (r"E:\Dennis\GamePadDex复刻\work\apk\inject.dex", "inject.dex")):
    if os.path.exists(src):
        shutil.copy2(src, os.path.join(mod, dst))
        print("copied", dst, os.path.getsize(src))
    else:
        print("MISSING", src)

print("module at", mod)
