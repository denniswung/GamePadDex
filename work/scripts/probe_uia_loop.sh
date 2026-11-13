#!/system/bin/sh
i=0
while [ $i -lt 4 ]; do
  rm -f /data/local/tmp/loop.xml
  out=$(su -M -c 'uiautomator dump --compressed /data/local/tmp/loop.xml' 2>&1 | tail -1)
  sz=$(wc -c < /data/local/tmp/loop.xml 2>/dev/null || echo 0)
  echo "run $i: size=$sz msg=$out"
  i=$((i+1))
  sleep 1
done
