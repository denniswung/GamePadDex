#!/system/bin/sh
CTL=/data/local/tmp/gpmctl
SOCK=/data/adb/gpm/gpmctl.sock
$CTL "$SOCK" '?' > /data/local/tmp/v169_cap.txt 2>&1
echo "--- first 6 ---"; head -6 /data/local/tmp/v169_cap.txt
echo "--- last 6 ---"; tail -6 /data/local/tmp/v169_cap.txt
echo "cap_lines=$(grep -ac '^CAP ' /data/local/tmp/v169_cap.txt)"
echo "cap_one=$(grep -a '^CAP ' /data/local/tmp/v169_cap.txt | grep -acE '1$')"
echo "err_lines=$(grep -ac '^ERR ' /data/local/tmp/v169_cap.txt)"
echo "--- line numbers 84-92 of extra script ---"
sed -n '84,92p' /data/local/tmp/verify_v169_extra.sh
