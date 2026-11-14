import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()

group = '''
echo "===== H. 打开应用 / 光标重居中（v1.63 修复）====="
# H1: Start+上 -> 打开 PiliPlus（用 keyvhat 模拟竖直方向键）
stop_engine
svc_del_keys(){ XML=$(xmlp); awk -v pat="$1" '$0 !~ pat' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }
svc_del_keys 'name="mix_(0|1|9|11|12)_'
svc_set mix_11_keys start+up
svc_set mix_11_action open_app
svc_set mix_11_value com.example.piliplus
start_engine
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c
$VG keyvhat 315 -1 500 >/dev/null 2>&1
sleep 3
O=$(top)
case "$O" in com.example.piliplus*) ok "H1 Start+上 打开 PiliPlus（$O）";; *) bad "H1 Start+上 打开应用（$O）";; esac

# H2: 指针空闲隐藏后重建 -> 自动回中心（不再卡边界）
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
[ "$R" -ge 1 ] && ok "H2 指针重建后自动回中心（$R 次）" || bad "H2 指针重建未回中心"

# H3: d-pad 确认后摇杆四个方向都能动（不卡边界）
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1
logcat -c
$VG stick 0 20000 700 2000 >/dev/null 2>&1
$VG stick 0 -20000 700 0 >/dev/null 2>&1
$VG stick 1 20000 700 0 >/dev/null 2>&1
$VG stick 1 -20000 700 0 >/dev/null 2>&1
sleep 0.6
LOG=$(logcat -d -s DexPad | grep -a 'ptr move')
POSX=$(echo "$LOG" | grep -ac 'dx=[1-9]')
NEGX=$(echo "$LOG" | grep -ac 'dx=-')
POSY=$(echo "$LOG" | grep -ac 'dy=[1-9]')
NEGY=$(echo "$LOG" | grep -ac 'dy=-')
[ "$POSX" -ge 1 ] && [ "$NEGX" -ge 1 ] && [ "$POSY" -ge 1 ] && [ "$NEGY" -ge 1 ] \\
  && ok "H3 光标四向都能移动（+x=$POSX -x=$NEGX +y=$POSY -y=$NEGY）" \\
  || bad "H3 光标方向受限（+x=$POSX -x=$NEGX +y=$POSY -y=$NEGY）"

# 清掉测试组合
stop_engine
svc_del_keys 'name="mix_(0|1|9|10|11|12)_'
start_engine

'''
anchor = 'echo "===== C. 系统动作实际效果 ====="'
if anchor not in s:
    raise SystemExit("anchor missing")
s = s.replace(anchor, group + anchor, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("suite updated")
