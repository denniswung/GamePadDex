#!/system/bin/sh
echo "== alive check =="
echo "pid: $(pidof com.dennis.dexpad)"
dumpsys activity services com.dennis.dexpad 2>/dev/null | grep -m1 'EngineService'

echo "== kill engine process =="
kill -9 $(pidof com.dennis.dexpad) 2>/dev/null
sleep 14
echo "pid after: $(pidof com.dennis.dexpad)"
dumpsys activity services com.dennis.dexpad 2>/dev/null | grep -m1 'EngineService'
tail -4 /data/local/tmp/gpm-module.log

echo "== mapping works after restart (L3 center) =="
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -1
