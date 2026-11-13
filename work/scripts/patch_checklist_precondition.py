import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()
marker = "# ---------- A. connection ----------"
assert marker in src
head_end = src.index(marker)

prefix = src[:head_end]
# keep the helpers (ok/bad/pos/engine...), replace the ad-hoc startup with a gate
cut = prefix.index("wake\nsvc power stayon true")
keep = prefix[:cut]

new_prefix = keep + '''wake
svc power stayon true >/dev/null 2>&1

# ---------- precondition: never judge cases on a broken link ----------
if ! sh /data/local/tmp/dexpad_precondition.sh; then
    echo "ABORT: precondition not met, no test case was judged"
    svc power stayon false >/dev/null 2>&1
    exit 2
fi
ok "A0 link healthy (precondition)"
logcat -c
/data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'helper ready'; then ok "A1 helper ready"; else bad "A1 helper ready"; fi

'''
src = new_prefix + src[head_end:]
io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
