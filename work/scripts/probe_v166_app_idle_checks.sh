#!/system/bin/sh
# 空闲 30s 内 App 发出的真实光标查询次数（应=0：只有 L3/撞边才发）
su -c ': > /data/adb/gpm/helper.log'
sleep 30
echo "idle_cursorq=$(grep -ac 'CURSORQ' /data/adb/gpm/helper.log 2>/dev/null)"
echo "idle_cursor=$(grep -ac '^CURSOR ' /data/adb/gpm/helper.log 2>/dev/null)"
echo "engine_pid=$(pidof com.dennis.dexpad)"
echo "apk_sha=$(sha256sum $(pm path com.dennis.dexpad | sed 's/package://') | cut -d' ' -f1)"
echo "helper_sha=$(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
