#!/system/bin/sh
P=com.dennis.padtest
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
has(){ logcat -d -s PadProbe 2>/dev/null | grep -qE "$1"; }
chk(){ if has "$2"; then ok "$1"; else bad "$1"; fi; }
dump(){ uiautomator dump --compressed /data/local/tmp/pt.xml >/dev/null 2>&1; }
xy(){ tr '>' '\n' < /data/local/tmp/pt.xml 2>/dev/null | grep -- "$1" | head -1 |
        sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'; }
tapb(){ set -- $1; input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); }

am force-stop $P; sleep 0.6
logcat -c
am start -n $P/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
chk "① 自检页打开" 'SYSTEM/page resume'

logcat -c; $VG key 304 120 2000 >/dev/null 2>&1; sleep 0.7
chk "② 自检页收到点击(注入链路)" 'MOUSE/click-down'

logcat -c; $VG stick 4 20000 700 0 >/dev/null 2>&1; sleep 0.9
if has 'WHEEL/|TOUCH/|MOUSE/drag'; then ok "③ 自检页收到滚动（触摸或滚轮后端）"; else bad "③ 自检页收到滚动"; fi

logcat -c; $VG key 318 120 0 >/dev/null 2>&1; sleep 0.7
chk "④ 自检页收到按键(静音)" 'KEY/key-down'

logcat -c; am start -n $P/.ui.CursorTestActivity >/dev/null 2>&1; sleep 1.5
chk "⑤ 光标页打开" 'page resume 光标测试'
logcat -c; $VG stick 0 20000 700 2000 >/dev/null 2>&1; sleep 0.8
chk "⑥ 光标页收到移动" 'MOUSE/hover'
logcat -c; $VG key 304 120 0 >/dev/null 2>&1; sleep 0.7
chk "⑦ 光标页收到点击" 'MOUSE/click-down'

logcat -c; am start -n $P/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.5
chk "⑧ 滚动页打开" 'page resume 滚动'
logcat -c; $VG stick 4 20000 900 2000 >/dev/null 2>&1; sleep 1.0
if has 'TOUCH/swipe|WHEEL/'; then ok "⑨ 滚动页收到滚动输出"; else bad "⑨ 滚动页收到滚动输出"; fi

logcat -c; am start -n $P/.ui.KeyTestActivity >/dev/null 2>&1; sleep 1.5
chk "⑩ 按键页打开" 'page resume 按键'
logcat -c; $VG key 312 120 1500 >/dev/null 2>&1; sleep 0.8
chk "⑪ 按键页收到按键（LT→Ctrl+Minus）" 'KEY/key-(down|up)'

logcat -c; am start -n $P/.ui.SystemTestActivity >/dev/null 2>&1; sleep 1.5
chk "⑫ 系统页打开" 'page resume 系统'
logcat -c; $VG key 313 120 0 >/dev/null 2>&1; sleep 0.9
chk "⑬ 系统页收到缩放注入键（RT→Ctrl+Plus）" 'KEY/key-down'

logcat -c; am start -n $P/.ui.LogActivity >/dev/null 2>&1; sleep 1.5
chk "⑭ 日志页打开" 'page resume 事件日志'

# 导出：点日志页的「导出 CSV」
for i in 1 2 3; do dump; B=$(xy 'text="导出 CSV"'); [ -n "$B" ] && break; sleep 1; done
B=$(xy 'text="导出 CSV"')
if [ -n "$B" ]; then
    tapb "$B"; sleep 1.5
    F=$(ls /sdcard/Android/data/$P/files/export/probe-log-*.csv 2>/dev/null | tail -1)
    if [ -n "$F" ]; then ok "⑮ 日志导出 CSV（$(wc -l < "$F") 行）"; else bad "⑮ 日志导出 CSV"; fi
else
    bad "⑮ 找不到导出按钮"
fi

logcat -c; am start -n $P/.ui.ReportActivity >/dev/null 2>&1; sleep 1.5
chk "⑯ 报告页打开" 'page resume 测试报告'

CR=$(logcat -b crash -d 2>/dev/null | grep -c 'com.dennis.padtest')
[ "$CR" -eq 0 ] && ok "⑰ 全程无崩溃" || bad "⑰ 崩溃 $CR 次"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
