import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()
old = '''[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "K-10 L3 centre + stick lock" || bad "K-10 L3 lock ($P0->$P1)"'''
new = '''# 允许 ~10px：锁定窗结束后摇杆仍在推，且 L3 归中本身会让 hover 尾部有 1~2px 抖动
D=$(awk -v a="$P0" -v b="$P1" 'BEGIN{d=a-b; if(d<0)d=-d; printf "%.1f", d}')
if [ -n "$P0" ] && [ -n "$D" ] && awk -v d="$D" 'BEGIN{exit !(d<10)}'; then
    ok "K-10 L3 centre + stick lock (Δ=${D}px)"
else
    bad "K-10 L3 lock ($P0->$P1)"
fi'''
if old not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
