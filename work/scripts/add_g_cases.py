import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

# 版本断言接受 1.6x
s = s.replace('case "$V" in 1.6[01]) ok "A1 映射 App 版本 $V";; *) bad "A1 版本=$V";; esac',
              'case "$V" in 1.6*) ok "A1 映射 App 版本 $V";; *) bad "A1 版本=$V";; esac')

grp = '''
echo "===== G. 双击 / 组合方向（v1.62 修复）====="
# G1: X 双击 = 多任务
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG double 307 60 120 >/dev/null 2>&1
sleep 2
D=$(logcat -d -s DexPad | grep -ac 'double x -> recents')
A=$(top)
case "$A" in *RecentsActivity*|*quickstep*) TOK=1;; *) TOK=0;; esac
[ "$D" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "G1 X 双击 → 多任务（$A）" || bad "G1 X 双击（log=$D top=$A）"

# G2: 慢双击（300ms 间隔）也能识别
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
$VG double 307 70 300 >/dev/null 2>&1
sleep 2
A=$(top)
case "$A" in *RecentsActivity*|*quickstep*) ok "G2 慢双击（300ms）也识别";; *) bad "G2 慢双击（$A）";; esac

# G3: X+LB = 内容向右（手指向右）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
: > /data/adb/gpm/helper.log
$VG combo 307 310 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \\([0-9]*\\),.*/\\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \\([0-9]*\\),.*/\\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -gt "$X0" ] && ok "G3 X+LB 手指向右（$X0→$X1）" || bad "G3 X+LB 方向（$S）"

# G4: X+RB = 内容向左（手指向左）
: > /data/adb/gpm/helper.log
$VG combo 307 311 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \\([0-9]*\\),.*/\\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \\([0-9]*\\),.*/\\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -lt "$X0" ] && ok "G4 X+RB 手指向左（$X0→$X1）" || bad "G4 X+RB 方向（$S）"

'''
anchor = 'echo "===== C. 系统动作实际效果 ====="'
if anchor not in s:
    raise SystemExit("anchor missing")
s = s.replace(anchor, grp + anchor, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("suite updated")
