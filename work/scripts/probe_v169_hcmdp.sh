#!/system/bin/sh
# probe_v169_hcmd_p.sh -- 通过引擎 HCMD 通道验证 P（t46 用法）
RES=/data/local/tmp/v169_hcmdp.txt
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
hcmd() { am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
log "helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad)"
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
hcmd "c"; sleep 1
log "before: $(grep -a '^CURSOR ' /data/adb/gpm/helper.log | tail -1)"
hcmd "P 400 1200 2560 1600"; sleep 1.6
log "after P: $(grep -a '^POSPTR' /data/adb/gpm/helper.log | tail -1)"
hcmd "c"; sleep 1
log "cursor: $(grep -a '^CURSOR ' /data/adb/gpm/helper.log | tail -1)"
hcmd "P 2000 300 2560 1600"; sleep 1.6
hcmd "c"; sleep 1
log "cursor2: $(grep -a '^CURSOR ' /data/adb/gpm/helper.log | tail -1)"
