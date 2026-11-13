import io
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v148_release_smoke.sh"
s = io.open(p, encoding="utf-8").read()

old1 = '''echo "$S1" | grep -q 'scroll_swipe_up' && ok "RB -> 内容下滑" || bad "RB 方向"'''
new1 = '''Y0=$(echo "$S1" | sed -n 's/.*SWIPE [0-9]* [0-9]*,@@start@@\\([0-9]*\\) ->.*/\\1/p'.replace('@@start@@', ''))
Y1=$(echo "$S1" | sed -n 's/.* -> [0-9]*,@@end@@\\([0-9]*\\) .*/\\1/p'.replace('@@end@@', ''))
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "RB -> 手指上滑/内容下滑 ($Y0->$Y1)" || bad "RB 方向 ($Y0->$Y1)"'''

old2 = '''echo "$S2" | grep -q 'scroll_swipe_down' && ok "LB -> 内容上滚" || bad "LB 方向"'''
new2 = '''Y2=$(echo "$S2" | sed -n 's/.*SWIPE [0-9]* [0-9]*,@@start2@@\\([0-9]*\\) ->.*/\\1/p'.replace('@@start2@@', ''))
Y3=$(echo "$S2" | sed -n 's/.* -> [0-9]*,@@end2@@\\([0-9]*\\) .*/\\1/p'.replace('@@end2@@', ''))
[ -n "$Y2" ] && [ -n "$Y3" ] && [ "$Y3" -gt "$Y2" ] && ok "LB -> 手指下滑/内容上滚 ($Y2->$Y3)" || bad "LB 方向 ($Y2->$Y3)"'''

if old1 not in s or old2 not in s:
    print("MISS"); raise SystemExit(1)
s = s.replace(old1, new1, 1).replace(old2, new2, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
