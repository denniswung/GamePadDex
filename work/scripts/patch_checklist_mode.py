import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''sh /data/local/tmp/dexpad_restart_clean.sh >/dev/null 2>&1
sleep 6
# a previous run may have left the SHARE switch off; that makes every action a
# no-op, so normalise it before anything else
PREFXML=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
if grep -q 'name="mode_on" value="false"' "$PREFXML" 2>/dev/null; then
    logcat -c
    /data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
    sleep 2
fi'''
new = '''PREFXML=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
sh /data/local/tmp/dexpad_restart_clean.sh >/dev/null 2>&1
sleep 6
# a previous run may have left the SHARE switch off; that makes every action a
# no-op, so normalise it before anything else
i=0
while [ $i -lt 4 ]; do
    if ! grep -q 'name="mode_on" value="false"' "$PREFXML" 2>/dev/null; then break; fi
    logcat -c
    /data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
    sleep 2
    i=$((i+1))
done'''
assert old in src
src = src.replace(old, new, 1)

# leave the switch ON at the end of the run
old_tail = '''svc power stayon false >/dev/null 2>&1'''
new_tail = '''# keep the device usable after the test: mouse mode must end ON
if grep -q 'name="mode_on" value="false"' "$PREFXML" 2>/dev/null; then
    /data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
    sleep 1
fi
svc power stayon false >/dev/null 2>&1'''
assert old_tail in src
src = src.replace(old_tail, new_tail, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
