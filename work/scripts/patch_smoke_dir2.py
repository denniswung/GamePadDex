import io, re
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v148_release_smoke.sh"
s = io.open(p, encoding="utf-8").read()

start = s.index('S1=$(hl "$L" | grep -m1 \'SWIPE\')')
end = s.index('# 桌面：LB/RB 转方向键')
block = r'''S1=$(hl "$L" | grep -m1 'SWIPE'); echo "      RB: $S1"
Y0=$(echo "$S1" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S1" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "RB -> 手指上滑/内容下滑 ($Y0->$Y1)" || bad "RB 方向 ($Y0->$Y1)"
logcat -c; L=$(hc); $VG key 310 400 0 >/dev/null 2>&1; sleep 1.0
S2=$(hl "$L" | grep -m1 'SWIPE'); echo "      LB: $S2"
Y2=$(echo "$S2" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y3=$(echo "$S2" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y2" ] && [ -n "$Y3" ] && [ "$Y3" -gt "$Y2" ] && ok "LB -> 手指下滑/内容上滚 ($Y2->$Y3)" || bad "LB 方向 ($Y2->$Y3)"

'''
s = s[:start] + block + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
