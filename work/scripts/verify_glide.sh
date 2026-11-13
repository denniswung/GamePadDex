#!/system/bin/sh
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5

echo "=== A) 松手后是否还有位移（清理日志后再观察）==="
$VG stick 0 20000 500 2000 >/dev/null 2>&1
sleep 0.35
logcat -c
sleep 0.9
N=$(logcat -d -s DexPad | grep -c 'ptr move')
echo "   松手 350ms 后 0.9s 内的 ptr move 行数 = $N（期望 0）"
logcat -d -s DexPad | grep 'ptr move' | sed 's/^.*DexPad  : /     /' | head -3

echo "=== B) hover 位置在松手后是否还变 ==="
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.15
P1=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
sleep 0.8
P2=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
echo "   松手 150ms: $P1"
echo "   松手 950ms: $P2"
[ "$P1" = "$P2" ] && echo "   => 不再滑行" || echo "   => 仍在滑行"
