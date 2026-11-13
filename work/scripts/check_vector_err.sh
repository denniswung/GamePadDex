#!/system/bin/sh
L=$(ls -t /data/adb/lspd/log/verbose_*.log 2>/dev/null | head -1)
echo "log: $L"
echo "=== errors / exceptions ==="
grep -nE ' E/|Exception|error|Error|fail|Fail' "$L" 2>/dev/null | tail -20
echo "=== manager related ==="
grep -nE 'manager|Manager|binder|Binder' "$L" 2>/dev/null | tail -12
echo "=== daemon state files ==="
ls -l /data/adb/lspd/ 2>/dev/null
echo "=== vector processes ==="
ps -A -o PID,NAME | grep -iE 'vectord|vector' | grep -v grep | head -5
