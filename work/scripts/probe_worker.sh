#!/system/bin/sh
echo "--- worker script ---"
cat /data/adb/gpm/focus_shell.sh 2>/dev/null
echo "--- pid file ---"
cat /data/adb/gpm/focus_shell.pid 2>/dev/null; echo
echo "--- start manually ---"
rm -f /data/adb/gpm/focus_done /data/adb/gpm/focus_req /data/local/tmp/gpm_focus_ui.xml
(setsid su -M -c 'echo $$ > /data/adb/gpm/focus_shell.pid; exec sh /data/adb/gpm/focus_shell.sh' </dev/null >/dev/null 2>&1 &)
sleep 1.5
echo "pid now: $(cat /data/adb/gpm/focus_shell.pid 2>/dev/null)"
touch /data/adb/gpm/focus_req
sleep 3.5
echo "done marker: $(ls /data/adb/gpm/focus_done 2>/dev/null | wc -l)"
echo "dump size: $(wc -c < /data/local/tmp/gpm_focus_ui.xml 2>/dev/null || echo 0)"
echo "--- loop again ---"
rm -f /data/adb/gpm/focus_done
touch /data/adb/gpm/focus_req
sleep 3.5
echo "done marker2: $(ls /data/adb/gpm/focus_done 2>/dev/null | wc -l)"
echo "dump size2: $(wc -c < /data/local/tmp/gpm_focus_ui.xml 2>/dev/null || echo 0)"
