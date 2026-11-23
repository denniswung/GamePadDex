#!/system/bin/sh
# probe_v166_state.sh -- v1.66 诊断：环境/显示/方向/偏好 基线快照（只读，不改任何设置）
# 用法：adb push work/scripts/probe_v166_state.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_state.sh"
# 输出：/data/local/tmp/v166_state.log
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
OUT=/data/local/tmp/v166_state.log
: > "$OUT"
L(){ echo "$@" >> "$OUT"; echo "$@"; }

L "=== A. 设备身份（写操作前必须核对）==="
L "model=$(getprop ro.product.model) serial=$(getprop ro.serialno) rel=$(getprop ro.build.version.release) sdk=$(getprop ro.build.version.sdk)"
L "fingerprint=$(getprop ro.build.fingerprint)"

L ""
L "=== B. 安装与进程 ==="
L "dexpad: $(dumpsys package $PKG | grep -m1 versionName | tr -d ' ') code=$(dumpsys package $PKG | grep -m1 versionCode | tr -d ' ') updated=$(dumpsys package $PKG | grep -m1 lastUpdateTime | tr -d ' ')"
L "debuggable=$(dumpsys package $PKG | grep -m1 privateFlags | grep -c DEBUGGABLE)"
L "padtest: $(dumpsys package $PAD | grep -m1 versionName | tr -d ' ')"
L "ps: $(ps -A -o PID,NAME | grep -E 'gpminput|com.dennis.dexpad|padtest' | tr '\n' ' ')"

L ""
L "=== C. 真实首选项（/data/misc/user/0/prefs）==="
L "$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"

L ""
L "=== D. 显示与方向（item 5）==="
L "wm size: $(wm size | tr '\n' ' ')"
L "wm density: $(wm density | tr '\n' ' ')"
L "global display_size_forced=$(settings get global display_size_forced)"
L "system user_rotation=$(settings get system user_rotation) accelerometer_rotation=$(settings get system accelerometer_rotation)"
L "system pointer_speed=$(settings get system pointer_speed) touchpad_pointer_speed=$(settings get system touchpad_pointer_speed)"
L "system mouse_pointer_size_step=$(settings get system mouse_pointer_size_step) enhance_pointer_precision=$(settings get system enhance_pointer_precision) dex_flow_pointer=$(settings get system dex_flow_pointer)"

# per-display: id -> (override real WxH, rotation, state, type)
L "-- dumpsys display 每个 display 的 override real / rotation / state --"
dumpsys display 2>/dev/null | awk '
  /mDisplayId=/ { id=$0; sub(/.*mDisplayId=/,"",id) }
  /mOverrideDisplayInfo=DisplayInfo\{/ {
    line=$0;
    name=""; real=""; rot=""; st="";
    if (match(line,/DisplayInfo\{"[^"]*"/)) name=substr(line,RSTART+11,RLENGTH-11);
    if (match(line,/real [0-9]+ x [0-9]+/)) real=substr(line,RSTART+5,RLENGTH-5);
    if (match(line,/rotation [0-9]/)) rot=substr(line,RSTART+9,1);
    if (match(line,/state [A-Z]+/)) st=substr(line,RSTART+6,RLENGTH-6);
    printf "  display %s: %s override-real=%s rotation=%s state=%s\n", id, name, real, rot, st;
  }'

L "-- dumpsys window displays 每个 display 的 mBounds / mRotation / ignoreOrientation --"
dumpsys window displays 2>/dev/null | awk '
  /^  Display: mDisplayId=/ { id=$0; sub(/.*mDisplayId=/,"",id); sub(/[^0-9].*/,"",id); blk=id }
  blk!="" && /overrideConfig=\{/ {
    b=""; if (match($0,/mBounds=Rect\([0-9 ,.-]+\)/)) b=substr($0,RSTART,RLENGTH);
    printf "  display %s overrideConfig %s\n", blk, b;
  }
  blk!="" && /^    mRotation=/ { printf "  display %s %s\n", blk, $1 }
  blk!="" && /^    mSetIgnoreOrientationRequest=/ { printf "  display %s %s\n", blk, $1 }
  blk!="" && /init=[0-9]+x[0-9]+ .*base=[0-9]+x[0-9]+ .*cur=[0-9]+x[0-9]+/ {
    printf "  display %s %s\n", blk, $0;
  }'

L ""
L "=== E. 前台与任务边界缓存（串扰 item 1 相关）==="
L "mCurrentFocus=$(dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | sed 's/^ *//')"
L "mFocusedApp=$(dumpsys window 2>/dev/null | grep -m1 mFocusedApp | sed 's/^ *//')"
L "helper top.txt=$(cat /data/adb/gpm/top.txt 2>/dev/null | tr -d '\n')"
L "helper taskbounds.txt=$(cat /data/adb/gpm/taskbounds.txt 2>/dev/null | tr -d '\n') mtime=$(stat -c %y /data/adb/gpm/taskbounds.txt 2>/dev/null)"
L "focused task bounds(实时): $(dumpsys activity activities 2>/dev/null | grep -A14 'topResumedActivity' | grep -m1 'mBounds=Rect' | sed 's/^ *//')"

L ""
L "=== F. 引擎状态（最近日志）==="
L "$(logcat -d -s DexPad 2>/dev/null | tail -12)"
L ""
L "=== G. 助手日志尾部 ==="
L "$(tail -8 /data/adb/gpm/helper.log 2>/dev/null)"
L ""
L "DONE -> $OUT"
