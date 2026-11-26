#!/system/bin/sh
S=/data/adb/gpm/gpmctl.sock
echo "== ctl ? =="
timeout 5 /data/local/tmp/sockcmd "$S" "?" 2>&1 | head -6
echo "== ctl P =="
timeout 5 /data/local/tmp/sockcmd "$S" "P 1280 1000 2560 1600" 2>&1 | head -4
sleep 2
echo "== ctl c =="
timeout 5 /data/local/tmp/sockcmd "$S" "c" 2>&1 | head -3
echo "== non-root =="
su 1000 -c "timeout 3 /data/local/tmp/sockcmd $S '?'" 2>&1 | head -3
echo "== helper log tail =="
grep -a -E 'CTL|POSPTR|CURSOR ' /data/adb/gpm/helper.log | tail -8
