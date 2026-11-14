import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

# A1 接受 1.61
s = s.replace('[ "$V" = "1.60" ] && ok "A1 映射 App 版本 $V" || bad "A1 版本=$V"',
              'case "$V" in 1.6[01]) ok "A1 映射 App 版本 $V";; *) bad "A1 版本=$V";; esac')

# F1：用测试 App 的 T10（方向键 + A 真的点中了按钮）判定
old_f1 = '''# F1: d-pad 选中后等 2 秒再按 A —— 必须真的"确认"（进入子页面）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
B=$(top)
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.0
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
A=$(top)
[ "$A" != "$B" ] && ok "F1 d-pad 选中后 A 确认（$B -> $A）" || bad "F1 d-pad 后 A 未确认（$B -> $A）"'''
new_f1 = '''# F1: d-pad 选中后等 2 秒再按 A —— 测试 App 自己确认按钮被点中（T10）
rm -f "$RPT"
start_auto
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.2
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.0
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
pull_report
flag "T10 方向键确认" && ok "F1 d-pad 选中后 A 确认（T10）" || bad "F1 d-pad 后 A 未确认（T10）"'''
if old_f1 not in s:
    raise SystemExit("F1 anchor missing")
s = s.replace(old_f1, new_f1, 1)

# F4：用 hat 长按（hold 20 是错误用法）
s = s.replace('$VG hold 20 1500 >/dev/null 2>&1 2>/dev/null || $VG hat 0 1 1500 >/dev/null 2>&1',
              '$VG hat 0 1 1600 >/dev/null 2>&1')

# C3：截图阈值放宽（通知栏展开时截图差异可能只有 ~200 字节）
s = s.replace('[ "$D" -gt 300 ] && ok "C3 SELECT 通知栏（$S0->$S1）"',
              '[ "$D" -gt 80 ] && ok "C3 SELECT 通知栏（$S0->$S1）"')

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("suite updated")
