#!/system/bin/sh
# 验证一次性居中：连续按 L3，hover 应每次都落在同一点（屏幕中心），且只有一条 CENTER 记录
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

echo "=== 设备列表 ==="
grep -E 'Name=' /proc/bus/input/devices | grep -i gamepad

echo "=== 连按 3 次 L3，看 hover 是否每次都一样 ==="
for i in 1 2 3; do
    # 先随便推一下，制造偏移
    $VG stick 0 20000 250 0 >/dev/null 2>&1
    sleep 0.2
    logcat -c
    $VG key 317 100 1200 >/dev/null 2>&1
    sleep 1.0
    H=$(dumpsys input 2>/dev/null | grep -m1 -o 'at ([0-9.]*, [0-9.]*)')
    C=$(logcat -d -s DexPad | grep -c 'cursor centered')
    A=$(grep -ac 'CENTER(abs' /data/adb/gpm/helper.log)
    L=$(grep -ac 'CENTER(linear' /data/adb/gpm/helper.log)
    echo "  第 $i 次: hover=$H  centered日志=$C  abs居中=$A  线性兜底=$L"
done
echo "=== 期望：hover 每次都是 800,1280（1600x2560 的一半）==="
echo "=== 助手最近一行 ==="
grep -a 'CENTER' /data/adb/gpm/helper.log | tail -2
