import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

old = '''# H2: 指针空闲隐藏后重建 -> 自动回中心（不再卡边界）
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.AutoTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
$VG hat 0 1 250 >/dev/null 2>&1
sleep 10
logcat -c
$VG stick 0 20000 1200 2000 >/dev/null 2>&1
sleep 0.6
R=$(logcat -d -s DexPad | grep -ac 're-centred')
[ "$R" -ge 1 ] && ok "H2 指针重建后自动回中心（$R 次）" || bad "H2 指针重建未回中心"'''

new = '''# H2: 指针空闲隐藏后重建 -> 恢复到"上次的位置"（不是回中心）
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
logcat -c
$VG stick 0 20000 700 2000 >/dev/null 2>&1
$VG stick 1 20000 500 0 >/dev/null 2>&1
sleep 0.6
LM=$(logcat -d -s DexPad | grep -a 'ptr move' | tail -1)
EX=$(echo "$LM" | sed -n 's/.*at \\([0-9]*\\),.*/\\1/p')
EY=$(echo "$LM" | sed -n 's/.*,\\([0-9]*\\)$/\\1/p')
sleep 9
logcat -c
$VG stick 0 4000 250 2000 >/dev/null 2>&1
sleep 1.2
SH=$(logcat -d -s DexPad | grep -a 'pointer shown at last position' | tail -1)
RX=$(echo "$SH" | sed -n 's/.*position \\([0-9]*\\),.*/\\1/p')
RY=$(echo "$SH" | sed -n 's/.*,\\([0-9]*\\) .*/\\1/p')
DX=$(( RX > EX ? RX - EX : EX - RX ))
DY=$(( RY > EY ? RY - EY : EY - RY ))
[ -n "$RX" ] && [ "$DX" -le 200 ] && [ "$DY" -le 200 ] \\
  && ok "H2 恢复上次位置（上次≈$EX,$EY 恢复=$RX,$RY）" \\
  || bad "H2 恢复位置（上次≈$EX,$EY 恢复=$RX,$RY）"'''

if old not in s:
    raise SystemExit("H2 anchor missing")
s = s.replace(old, new, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("H2 updated")
