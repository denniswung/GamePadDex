#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
SOCK=/data/data/$PKG/files/gpm.sock

send() { printf '%s\n' "$1" | timeout 2 nc -U "$SOCK" 2>/dev/null || true; }
# 没有 nc 时用助手的 stdin 方式不可行，这里直接用 socat 备选
if ! command -v nc >/dev/null 2>&1; then
    echo "no nc, use toybox nc"
fi

am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.2

echo "=== 关闭原生 d-pad 转发（I 0）==="
printf 'I 0\n' | nc -U "$SOCK" 2>/dev/null | head -2
sleep 0.3
grep -a 'DPAD_NATIVE' /data/adb/gpm/helper.log | tail -1

echo "=== 单独方向键（hat）==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
$VG hat 0 1 200 2000 >/dev/null 2>&1
sleep 0.9
echo "  --- DexPad ---"
logcat -d -s DexPad | grep -E 'button up|arrow key|pad key' | sed 's/^.*DexPad  : /    /' | head -3
echo "  helper: $(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -E 'AX .*1[56]|KEYON' | head -3 | tr '\n' '|')"

echo "=== X + 方向键（先 X 后 hat）==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG hold 307 1200 2000 >/dev/null 2>&1 & )
sleep 2.1
$VG hat 0 1 150 0 >/dev/null 2>&1
sleep 1.0
echo "  --- DexPad ---"
logcat -d -s DexPad | grep -E 'mix 0|volume up|button up' | sed 's/^.*DexPad  : /    /' | head -4

echo "=== 方向键先按、X 后按（顺序反过来）==="
logcat -c; L=$(wc -l < /data/adb/gpm/helper.log)
( $VG hold 307 900 2200 >/dev/null 2>&1 & )
$VG hat 0 -1 700 2000 >/dev/null 2>&1
sleep 1.2
echo "  --- DexPad ---"
logcat -d -s DexPad | grep -E 'mix 1|volume down|button down' | sed 's/^.*DexPad  : /    /' | head -4
