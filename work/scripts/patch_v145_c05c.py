import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()
old = '[ -n "$SW" ] && [ "$DX" -ge 900 ] && ok "C-05 X+LB wide swipe (${DX}px)" || bad "C-05 X+LB swipe (dx=$DX)"'
new = ('# 锚点改成光标后，距离取决于光标离边界的远近：明显大于小幅滑动(约 380px)即可\n'
       '[ -n "$SW" ] && [ "$DX" -ge 500 ] && ok "C-05 X+LB 横向滑动 (${DX}px)" || bad "C-05 X+LB swipe (dx=$DX)"')
if old not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
