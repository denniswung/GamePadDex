#!/system/bin/sh
echo "=== prefs 文件 ==="
ls -l /data/misc/*/prefs/com.dennis.dexpad/ 2>/dev/null
for f in /data/misc/*/prefs/com.dennis.dexpad/*.xml; do
  [ -f "$f" ] || continue
  echo "--- $f"
  grep -oE 'name="[a-zA-Z_]+" value="[^"]*"' "$f" | grep -E 'enabled|mode|center_gain|idle_hide' 
done

echo
echo "=== 引擎模式日志 ==="
logcat -d -s DexPad | grep -aE 'toggle|mouse mode|modeOn|enabled' | tail -5

echo
echo "=== 从 helper 域读前台（模拟）==="
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity || echo "  (dumpsys 无输出)"
echo "=== su -M 版本 ==="
su -M -c "dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity" 2>&1 | head -2
