#!/system/bin/sh
S=/data/adb/gpm/gpmctl.sock
echo "== sockcmd single arg =="
timeout 4 /data/local/tmp/sockcmd "$S" "P 1280 1000 2560 1600" 2>&1 | head -5
echo "rc1=$?"
echo "== sockcmd multi arg =="
timeout 4 /data/local/tmp/sockcmd "$S" P 1280 1000 2560 1600 2>&1 | head -5
echo "rc2=$?"
echo "== sockcmd stdin c =="
echo c | timeout 4 /data/local/tmp/sockcmd "$S" 2>&1 | head -5
echo "rc3=$?"
echo "== helper log =="
grep -a -E 'CTL|POSPTR|CURSOR' /data/adb/gpm/helper.log | tail -8
