import io
P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()
old = """grep -aq 'NOTIF uinput=1' /data/adb/gpm/helper.log && [ "$D" -gt 200 ] && ok "C3 SELECT 通知栏（$S0->$S1）" || bad "C3 SELECT 通知栏（$S0->$S1）\""""
new = """grep -aq 'NOTIF swipe' /data/adb/gpm/helper.log && [ "$D" -gt 500000 ] && ok "C3 SELECT 通知栏（$S0->$S1）" || bad "C3 SELECT 通知栏（$S0->$S1）\""""
if old not in s:
    raise SystemExit("C3 assert anchor missing")
s = s.replace(old, new, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("C3 assert updated")
