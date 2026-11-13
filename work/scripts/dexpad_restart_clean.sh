#!/system/bin/sh
# full reset: helper + engine (the helper session can outlive a killed app)
for hp in $(pidof gpminput); do kill -9 "$hp" 2>/dev/null; done
am force-stop com.dennis.dexpad
sleep 1
for p in $(ps -A -o PID,NAME | grep com.dennis.dexpad | grep -v grep | awk '{print $1}'); do
    kill -9 "$p" 2>/dev/null
done
sleep 1
sh /data/local/tmp/dexpad_start.sh >/dev/null 2>&1

# wait until the helper is up and the engine has connected to it
i=0
while [ $i -lt 6 ]; do
    sleep 3
    if [ -n "$(pidof gpminput)" ] && [ -n "$(pidof com.dennis.dexpad)" ]; then
        if logcat -d -s DexPadLink 2>/dev/null | grep -q 'helper ready'; then
            break
        fi
    fi
    sh /data/local/tmp/dexpad_start.sh >/dev/null 2>&1
    i=$((i+1))
done
sleep 2
echo "== procs =="
ps -A -o PID,NAME | grep -E 'dennis|gpminput' | grep -v grep
echo "== logs =="
logcat -d -s DexPad DexPadLink 2>/dev/null | grep -E 'helper ready|mouse mode|dpad native|dex from helper' | tail -5
