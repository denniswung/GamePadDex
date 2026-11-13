import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()

anchor = "# ---- C-05 X+LB wide swipe"
if anchor not in s:
    print("MISS anchor"); raise SystemExit(1)
s = s.replace(anchor,
    "# 先切到真实应用：桌面会被「方向键转发」接管，不会发生滑动\n"
    "am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1\n"
    "sleep 1.6\n" + anchor, 1)

old = '[ -n "$SW" ] && [ "$DX" -ge 1200 ] && ok "C-05 X+LB wide swipe (${DX}px)" || bad "C-05 X+LB swipe (dx=$DX)"'
new = ('# 现在锚点在光标上，滑动距离受光标位置限制：≥900px 即视为「大段滑动」\n'
       '[ -n "$SW" ] && [ "$DX" -ge 900 ] && ok "C-05 X+LB wide swipe (${DX}px)" || bad "C-05 X+LB swipe (dx=$DX)"')
if old not in s:
    print("MISS assert"); raise SystemExit(1)
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
