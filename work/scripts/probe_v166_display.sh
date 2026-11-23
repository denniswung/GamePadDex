#!/system/bin/sh
# probe_v166_display.sh -- item5：显示与方向基线（display_size_forced / wm size / mCurrentOrientation /
#                          overrideConfig+mBounds / 竖屏比例 / forceLandscape 与 setRotation(1) 叠加效果）
# 用法：adb push work/scripts/probe_v166_display.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_display.sh"
# 全部实验均可逆：脚本末尾恢复 display_size_forced=1600,2560 + user_rotation=1 + 重启引擎
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
LOG=/data/local/tmp/v166_display.log

: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
snap(){ # $1 label
  L "--- $1 ---"
  L "  wm size: $(wm size | tr '\n' ' ')"
  L "  display_size_forced=$(settings get global display_size_forced) user_rotation=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
  # display 0 的真实 app 尺寸/旋转/状态（override）
  dumpsys display 2>/dev/null | awk '
    /mDisplayId=/ { id=$0; sub(/.*mDisplayId=/,"",id) }
    /mOverrideDisplayInfo=DisplayInfo\{/ {
      real=""; rot=""; st="";
      if (match($0,/real [0-9]+ x [0-9]+/)) real=substr($0,RSTART+5,RLENGTH-5);
      if (match($0,/rotation [0-9]/)) rot=substr($0,RSTART+9,1);
      if (match($0,/state [A-Z]+/)) st=substr($0,RSTART+6,RLENGTH-6);
      if (id+0==0) printf "  display0 override: real=%s rotation=%s state=%s\n", real, rot, st;
    }'
  L "  display0 overrideConfig/mBounds/mRotation/ignoreOrientation:"
  dumpsys window displays 2>/dev/null | awk '
    /^  Display: mDisplayId=/ { id=$0; sub(/.*mDisplayId=/,"",id); sub(/[^0-9].*/,"",id); }
    id+0==0 && /^    init=[0-9]+x[0-9]+/ { print "    " $0 }
    id+0==0 && /overrideConfig=\{/ && match($0,/mBounds=Rect\([0-9 ,.-]+\)/) { print "    overrideConfig " substr($0,RSTART,RLENGTH) }
    id+0==0 && /^    mRotation=/ { print "    " $1 }
    id+0==0 && /^    mSetIgnoreOrientationRequest=/ { print "    " $1 }
    id+0==0 && /^    mCurrentFocus=/ { print "    " $0 }'
  L "  mCurrentOrientation(每屏): $(dumpsys display 2>/dev/null | awk '/DisplayDeviceInfo\{/{if(match($0,/"[^"]+"/)) n=substr($0,RSTART,RLENGTH)} /mCurrentOrientation=/{sub(/.*mCurrentOrientation=/,""); printf "%s=%s ", n, $1}')"
  L "  padtest window: $(dumpsys window windows 2>/dev/null | grep -A6 'Window{.*padtest' | grep -m1 'mFrame=' | sed 's/^ *//')"
}

L "=== 0. 起始状态（诊断开始时的真实状态记录在文档里；此处已被前序 probe 置为横屏）==="
wake; sleep 1
snap "A. 起始"

L ""
L "=== 1. 实验：user_rotation=0（竖屏）==="
settings put system user_rotation 0 >/dev/null 2>&1; sleep 2.5
snap "B. rotation=0"

L ""
L "=== 2. 实验：user_rotation=1（横屏）==="
settings put system user_rotation 1 >/dev/null 2>&1; sleep 2.5
snap "C. rotation=1"

L ""
L "=== 3. 实验：横屏下灭屏/亮屏（系统是否把 user_rotation 改回去）==="
input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 2
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 2
L "  亮屏后 user_rotation=$(settings get system user_rotation) forced=$(settings get global display_size_forced)"

L ""
L "=== 4. 实验：user_rotation=0 后重启引擎（force_landscape 默认 true 的 setRotation(1) 效果）==="
settings put system user_rotation 0 >/dev/null 2>&1; sleep 2
L "  重启前 user_rotation=$(settings get system user_rotation) display0=$(dumpsys display | grep -m1 -A2 'mDisplayId=0$' | tail -1 | cut -c1-80)"
am force-stop $PKG >/dev/null 2>&1; sleep 0.6
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 6
L "  重启后 user_rotation=$(settings get system user_rotation) helper_ROTATION=$(grep -a '^ROTATION' /data/adb/gpm/helper.log | tail -1)"
snap "D. 重启引擎后"

L ""
L "=== 5. 实验：wm size reset（去掉 forced override）在横屏下的真实 app 尺寸 ==="
wm size reset >/dev/null 2>&1; sleep 3
snap "E. wm size reset (rotation=$(settings get system user_rotation))"
L "  恢复 wm size 1600x2560"
wm size 1600x2560 >/dev/null 2>&1; sleep 3
snap "F. 恢复 forced 1600x2560"

L ""
L "=== 6. 结论用差值 ==="
L "  forced=$(settings get global display_size_forced) 物理=$(wm size | sed -n 's/Physical size: //p')"
PW=$(wm size | sed -n 's/Physical size: \([0-9]*\)x.*/\1/p'); PH=$(wm size | sed -n 's/Physical size: [0-9]*x\([0-9]*\)/\1/p')
L "  物理=${PW}x${PH} (${PW} < ${PH} -> 物理竖屏)"

L ""
L "DONE $(getprop ro.serialno) rotation=$(settings get system user_rotation) forced=$(settings get global display_size_forced)"
