#!/system/bin/sh
# KernelSU / Magisk late-start service for the DeX gamepad helper.
#
#   * keeps /data/adb/gpm/gpminput in sync with the module
#   * runs the helper as a daemon on the socket owned by com.dennis.dexpad
#   * restarts it when it dies and starts the app's mapping engine after boot
#
# IMPORTANT: this device runs KernelSU in late-load mode; ksud runs the service
# stage in a process group that is torn down when the stage finishes. The
# supervisor therefore re-executes itself detached in a new session and the
# short-lived boot script exits immediately (that is also how the charge_limit
# module keeps its watchers alive).
MODDIR=${0%/*}
PKG=com.dennis.dexpad
SOCKDIR=/data/data/$PKG/files
SOCK=$SOCKDIR/gpm.sock
BIN=$MODDIR/gpminput
DEX=$MODDIR/inject.dex

if [ "$1" != "--supervisor" ]; then
    setsid /system/bin/sh "$MODDIR/service.sh" --supervisor >/dev/null 2>&1 </dev/null &
    exit 0
fi

# --- detached supervisor from here on ---
export ANDROID_ROOT=/system
export ANDROID_DATA=/data
export LD_LIBRARY_PATH=/apex/com.android.art/lib64:/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64

mkdir -p /data/adb/gpm
# only one supervisor may run (a second one would spawn helpers that fight over
# the same EVIOCGRAB). toybox flock only accepts an fd, so use pgrep and
# exclude this very process.
RUNNING=$(pgrep -f 'gpm_dex/service.sh --supervisor' | grep -v "^$$$" | wc -l)
if [ "$RUNNING" -gt 0 ]; then
    exit 0
fi

[ -f "$DEX" ] && cp -f "$DEX" /data/adb/gpm/inject.dex && chmod 644 /data/adb/gpm/inject.dex
[ -f "$BIN" ] && cp -f "$BIN" /data/adb/gpm/gpminput && chmod 755 /data/adb/gpm/gpminput

# only one helper may run: a stale one would hold the grab and confuse the app
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 1

# start the mapping engine (foreground service of the module app) once the
# framework is up; the helper socket may not exist yet, the app retries
(
    i=0
    while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 180 ]; do
        sleep 1
        i=$((i+1))
    done
    k=0
    while [ $k -lt 12 ]; do
        am start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1 && break
        sleep 5
        k=$((k+1))
    done
) &

# watchdog: keep the mapping engine (foreground service) alive even if the
# user closes the config page or the system kills the app process.
# Samsung Freecess also freezes the (cached-looking) process even with a
# foreground service; a start request thaws it again, so ping every cycle.
(
    while true; do
        sleep 8
        if ! pidof com.dennis.dexpad >/dev/null 2>&1; then
            echo "engine missing, restarting" >>/data/local/tmp/gpm-module.log
            # a helper whose session died with the old app must not keep the
            # socket: restart both sides together so the new engine reconnects
            for hp in $(pidof gpminput); do kill -9 "$hp" 2>/dev/null; done
        fi
        am start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1
    done
) &

# wait for the app data dir (first launch can be late) - max 5 min
i=0
while [ ! -d "/data/data/$PKG" ] && [ $i -lt 300 ]; do
    sleep 1
    i=$((i+1))
done
mkdir -p "$SOCKDIR" 2>/dev/null

while true; do
    if [ ! -x /data/adb/gpm/gpminput ] || [ ! -d "$SOCKDIR" ]; then
        sleep 3
        continue
    fi
    # blocking run: when it exits we loop and restart it
    /data/adb/gpm/gpminput --socket "$SOCK" >>/data/local/tmp/gpm-module.log 2>&1
    echo "helper exited, restarting" >>/data/local/tmp/gpm-module.log
    # quick retry: a helper that exits immediately would be blocked by the
    # flock anyway, so a short back-off is enough for crash recovery
    sleep 2
done
