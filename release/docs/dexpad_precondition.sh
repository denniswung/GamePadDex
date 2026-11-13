#!/system/bin/sh
# Strict precondition gate for every test script: the mapping link must be
# healthy before any case is judged. Returns 0 only when a real key press
# produces a real action.
PREFXML=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
LOG=/data/adb/gpm/helper.log

i=0
while [ $i -lt 8 ]; do
    # helper process + socket
    if [ -z "$(pidof gpminput)" ]; then
        sh /data/local/tmp/dexpad_start.sh >/dev/null 2>&1
        sleep 3
        i=$((i+1))
        continue
    fi
    # mouse mode must be ON (persisted SHARE switch)
    if grep -q 'name="mode_on" value="false"' "$PREFXML" 2>/dev/null; then
        /data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
        sleep 2
        i=$((i+1))
        continue
    fi
    # real round trip: A must reach the engine and produce an action. While the
    # d-pad was the last input the engine translates A into DPAD_CENTER (native
    # navigation), which is just as good a proof that the link is alive.
    logcat -c
    /data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
    sleep 1
    if logcat -d -s DexPad 2>/dev/null | grep -qE 'left button down|A -> DPAD_CENTER'; then
        echo "PRECONDITION: link ok (helper $(pidof gpminput), mode on)"
        exit 0
    fi
    sh /data/local/tmp/dexpad_start.sh >/dev/null 2>&1
    sleep 3
    i=$((i+1))
done

echo "PRECONDITION FAILED: helper/engine link is not healthy (helper=$(pidof gpminput), mode=$(grep -o 'mode_on\" value=\"[a-z]*' "$PREFXML" 2>/dev/null))"
tail -3 "$LOG" 2>/dev/null
exit 2
