#!/system/bin/sh
# probe_v166_helper_capscreen.sh -- t11：空闲隐藏指针后，设置页「链路自检」仍应全部通过
# 1) 打开设置页并确认引擎已连接
# 2) HCMD h 销毁虚拟鼠标（等价 8s 空闲隐藏），等 9s
# 3) HCMD ? 在隐藏状态刷新自检，读 helper.log 新增的 CAP/INFO（不截断日志，按行数切片）
# 4) 重新打开设置页刷新状态，截图
PKG=com.dennis.dexpad
LOG=/data/adb/gpm/helper.log
R=/data/local/tmp/v166_capscreen.txt
log() { echo "$@" | tee -a "$R"; }
: > "$R"
log "== capscreen $(date) =="
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
am start -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 3
log "  engine=$(pidof $PKG) helper=$(pidof gpminput)"
log "  app caps (logcat): $(logcat -d | grep -a 'selftest ' | tail -1 | sed 's/.*selftest //')"
# 隐藏指针（销毁设备），并等 >8s
N=$(wc -l < "$LOG")
am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd h >/dev/null 2>&1
sleep 9
# 隐藏状态下刷新自检
am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd '?' >/dev/null 2>&1
sleep 2
NEW=$(tail -n +$((N + 1)) "$LOG")
log "  helper.log CAP/INFO while pointer hidden:"
echo "$NEW" | grep -a -E '^(CAP|INFO pointer|SELFTEST)' | sed 's/^/    /' | tee -a "$R" >/dev/null
log "  hidden CAP zero count=$(echo "$NEW" | grep -a '^CAP ' | awk '$3 == 0' | wc -l)"
log "  hidden INFO pointer: $(echo "$NEW" | grep -a '^INFO pointer' | head -1)"
log "  app caps after refresh (logcat): $(logcat -d | grep -a 'selftest ' | tail -1 | sed 's/.*selftest //')"
# 重新打开设置页 -> refreshStatus
am start -n $PKG/.ConfigActivity >/dev/null 2>&1
sleep 2
screencap -p /data/local/tmp/ui_config_hidden_t11.png
log "  screenshot=$(ls -l /data/local/tmp/ui_config_hidden_t11.png 2>/dev/null | awk '{print $5}') bytes"
# 恢复指针
am broadcast -a com.dennis.dexpad.HCMD -n $PKG/.DebugReceiver --es cmd j >/dev/null 2>&1
sleep 1
log "  pointer restored: $(tail -n 3 "$LOG" | tr '\n' ' ')"
log DONE
