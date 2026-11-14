import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

old_start = "# H2: 指针空闲隐藏后重建 -> 恢复到\"上次的位置\"（不是回中心）"
i = s.index(old_start)
j = s.index("# H3:", i)
new_h2 = '''# H2: 指针空闲隐藏后再用摇杆 -> 光标"隐形恢复"到上次位置（没有可见的修正移动）
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
logcat -c
$VG stick 0 20000 600 2000 >/dev/null 2>&1
sleep 0.5
H1L=$(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)
P1X=$(echo "$H1L" | sed -n 's/.*hover x=\\([0-9]*\\) y=.*/\\1/p')
P1Y=$(echo "$H1L" | sed -n 's/.*hover x=[0-9]* y=\\([0-9]*\\).*/\\1/p')
sleep 9
logcat -c
$VG stick 0 6000 250 2000 >/dev/null 2>&1
sleep 0.8
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
CL=$(logcat -d -s PadProbe | grep -a 'MOUSE/click-down' | tail -1)
P2X=$(echo "$CL" | sed -n 's/.*click-down x=\\([0-9]*\\) y=.*/\\1/p')
P2Y=$(echo "$CL" | sed -n 's/.*click-down x=[0-9]* y=\\([0-9]*\\).*/\\1/p')
DX=$(( P2X > P1X ? P2X - P1X : P1X - P2X ))
DY=$(( P2Y > P1Y ? P2Y - P1Y : P1Y - P2Y ))
[ -n "$P2X" ] && [ "$DX" -le 120 ] && [ "$DY" -le 120 ] \\
  && ok "H2 光标隐形恢复到上次位置（隐藏前 $P1X,$P1Y → 点击 $P2X,$P2Y）" \\
  || bad "H2 恢复位置（隐藏前 $P1X,$P1Y → 点击 $P2X,$P2Y）"

'''
s = s[:i] + new_h2 + s[j:]
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("H2 updated to invisible-restore check")
