#!/system/bin/sh
# write a logging worker and drive it manually
cat > /data/adb/gpm/wshell.sh <<'EOF'
#!/system/bin/sh
while :; do
  if [ -e /data/adb/gpm/focus_req ]; then
    rm -f /data/adb/gpm/focus_req
    /system/bin/uiautomator dump --compressed /data/local/tmp/gpm_focus_ui.xml >/data/adb/gpm/worker.log 2>&1
    echo "rc=$? size=$(wc -c < /data/local/tmp/gpm_focus_ui.xml 2>/dev/null || echo 0)" >> /data/adb/gpm/worker.log
    touch /data/adb/gpm/focus_done
  fi
  sleep 0.15
done
EOF
chmod 755 /data/adb/gpm/wshell.sh
pkill -f wshell.sh 2>/dev/null
rm -f /data/adb/gpm/focus_done /data/adb/gpm/focus_req /data/adb/gpm/worker.log /data/local/tmp/gpm_focus_ui.xml
(setsid su -M -c 'exec sh /data/adb/gpm/wshell.sh' </dev/null >/dev/null 2>&1 &)
sleep 1.2
touch /data/adb/gpm/focus_req
sleep 4
echo "done=$(ls /data/adb/gpm/focus_done 2>/dev/null | wc -l) size=$(wc -c < /data/local/tmp/gpm_focus_ui.xml 2>/dev/null || echo 0)"
echo "--- worker.log ---"
cat /data/adb/gpm/worker.log 2>/dev/null
