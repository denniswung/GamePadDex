import io
h = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(h, encoding="utf-8").read()
s = s.replace('snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop --user 0 %s", pkg);',
              'snprintf(cmd, sizeof(cmd), "/system/bin/sh -c \\"PATH=/system/bin cmd activity force-stop %s\\"", pkg);')
s = s.replace('system("/system/bin/cmd power wakeup");', 'system("/system/bin/sh -c \\"PATH=/system/bin cmd power wakeup\\"");')
# closeApp (CLOSE_APP) also uses am: switch to cmd activity
s = s.replace('snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop %s", app);',
              'snprintf(cmd, sizeof(cmd), "/system/bin/sh -c \\"PATH=/system/bin cmd activity force-stop %s\\"", app);')
io.open(h, "w", encoding="utf-8", newline="\n").write(s)

t = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
x = io.open(t, encoding="utf-8").read()
start = x.index("logcat -c\n$VG key 307 5000 2500 >/dev/null 2>&1 &")
end = x.index("# ---- L3 centre")
x = x[:start] + """logcat -c
$VG hat 0 1 400 2500 >/dev/null 2>&1
sleep 0.5
$VG key 304 200 2500 >/dev/null 2>&1
sleep 0.8
log | grep -q 'A -> DPAD_CENTER' && ok "K-01 D-pad then A = focus" || bad "K-01 A focus"

""" + x[end:]
io.open(t, "w", encoding="utf-8", newline="\n").write(x)
print("ok")
