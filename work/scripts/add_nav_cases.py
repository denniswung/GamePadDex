import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

nav = '''
echo "===== F. d-pad 导航 / 鼠标切换（v1.61 修复）====="
# F1: d-pad 选中后等 2 秒再按 A —— 必须真的"确认"（进入子页面）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
B=$(top)
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.0
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
A=$(top)
[ "$A" != "$B" ] && ok "F1 d-pad 选中后 A 确认（$B -> $A）" || bad "F1 d-pad 后 A 未确认（$B -> $A）"

# F2: 聚焦后按 A 不能变成"光标点击"（引擎日志必须是 DPAD_CENTER）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 1.0
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
D=$(logcat -d -s DexPad | grep -ac 'A -> DPAD_CENTER')
C=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$D" -ge 1 ] && [ "$C" -eq 0 ] && ok "F2 A 走 DPAD_CENTER（click=$C）" || bad "F2 A 注入方式（DPAD_CENTER=$D click=$C）"

# F3: d-pad 后用左摇杆 = 回到鼠标模式，A 恢复点击
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 9000 300 0 >/dev/null 2>&1
sleep 0.6
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
grep -q 'native navigation OFF (stick moved)' /dev/null 2>/dev/null
C=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$C" -ge 1 ] && ok "F3 摇杆后 A 回到鼠标点击" || bad "F3 摇杆后 A 仍是确认（click=$C）"

# F4: d-pad 按住连发（焦点连续移动）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
: > /data/adb/gpm/helper.log
$VG hold 20 1500 >/dev/null 2>&1 2>/dev/null || $VG hat 0 1 1500 >/dev/null 2>&1
sleep 1.2
N=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
N=${N:-0}
[ "$N" -ge 3 ] && ok "F4 d-pad 按住连发（$N 次）" || bad "F4 d-pad 连发（$N）"

'''

anchor = 'echo "===== C. 系统动作实际效果 ====="'
if anchor not in s:
    raise SystemExit("anchor missing")
s = s.replace(anchor, nav + anchor, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("suite updated")
