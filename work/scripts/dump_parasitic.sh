#!/system/bin/sh
L=$(ls -t /data/adb/lspd/log/verbose_*.log 2>/dev/null | head -1)
echo "log: $L"
grep -A 16 'Parasitic injection failed' "$L" 2>/dev/null | head -40
