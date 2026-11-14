import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

old = '''wake; sleep 0.5
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
screencap -p /data/local/tmp/n0.png 2>/dev/null'''

new = '''# 保证屏幕是亮的（长套件跑下来屏幕可能已经超时熄灭，截图会是全黑）
i=0
while [ $i -lt 4 ]; do
  wake; sleep 0.8
  screencap -p /data/local/tmp/n0.png 2>/dev/null
  SZ=$(wc -c < /data/local/tmp/n0.png)
  [ "$SZ" -gt 100000 ] && break
  input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  i=$((i+1))
done
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
wake; sleep 0.5
screencap -p /data/local/tmp/n0.png 2>/dev/null'''

if old not in s:
    raise SystemExit("C3 anchor missing")
s = s.replace(old, new, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("C3 hardened")
