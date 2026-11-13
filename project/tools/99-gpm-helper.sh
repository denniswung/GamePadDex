#!/system/bin/sh
# Gamepad Mouse (DeX) root helper - KernelSU / Magisk late-start script.
#
# Install (once, as root):
#   mkdir -p /data/adb/gpm
#   cp <gpminput> /data/adb/gpm/gpminput && chmod 755 /data/adb/gpm/gpminput
#   cp 99-gpm-helper.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/99-gpm-helper.sh
#
# The app connects to the unix socket from its own files dir, so no `su` prompt
# is needed at run time.  Without this script the app falls back to `su -c`.

PKG=com.dennis.gamepadmouse
BIN=/data/adb/gpm/gpminput
SOCKDIR=/data/data/$PKG/files
SOCK=$SOCKDIR/gpm.sock

# wait for the app data dir (first launch) - up to 5 minutes
i=0
while [ ! -d "/data/data/$PKG" ] && [ $i -lt 300 ]; do
    sleep 1
    i=$((i+1))
done
mkdir -p "$SOCKDIR" 2>/dev/null

while true; do
    if [ -x "$BIN" ] && [ -d "$SOCKDIR" ]; then
        "$BIN" --socket "$SOCK" >/dev/null 2>&1
    fi
    sleep 3
done
