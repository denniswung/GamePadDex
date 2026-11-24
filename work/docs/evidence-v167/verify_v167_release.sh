#!/system/bin/sh
# verify_v167_release.sh -- v1.67 release 字节（8aeef7b7）上的 LB/RB 机制 + 双击文案抽检
#
# release 包 debuggable=false，app 的 DEBUG/HCMD 广播被 DebugReceiver 主动忽略，
# 因此 v_touch_scroll 不能用 `am broadcast --es pref` 切换，改用「改 prefs XML + 重启引擎」
# （prefs 是 app 自己的存储：/data/misc/<user>/prefs/com.dennis.dexpad/dexpad.xml）。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
RES=/data/local/tmp/verify_v167_release.result
SHOTS=/data/local/tmp/v167_shots
EXPECT_APK="${EXPECT_APK:-8aeef7b7d6d5ea01b650a26e18c0eb8f0c4233f647a0cb0a17048be1e2180312}"
EXPECT_HELPER="${EXPECT_HELPER:-1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf}"
PASS=0; FAIL=0; FAILED=""
mkdir -p "$SHOTS" 2>/dev/null; : > "$RES"
L(){ echo "$@" | tee -a "$RES"; }
sec(){ L ""; L "===== $* ====="; }
ck(){ if [ "$4" = "PASS" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED $1"; fi
      L "[$1] $4 | 阈值: $2 | 实测: $3"; [ "$4" = "FAIL" ] && [ -n "$5" ] && L "     REPRO: $5"; return 0; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
prefs_path(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
vt(){ grep -o 'v_touch_scroll" value="[a-z]*"' "$(prefs_path)" 2>/dev/null | sed 's/.*value="//;s/"//'; }
set_vt(){ # $1 true|false : stop engine -> edit prefs -> start engine
  am force-stop $PKG >/dev/null 2>&1; sleep 1.0
  sed -i "s/v_touch_scroll\" value=\"[a-z]*\"/v_touch_scroll\" value=\"$1\"/" "$(prefs_path)" 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0
  while [ $i -lt 20 ]; do
    i=$((i+1)); sleep 0.6
    pidof $PKG >/dev/null 2>&1 && [ "$(vt)" = "$1" ] && { sleep 1.2; return 0; }
  done
  return 1
}
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; sleep 0.4; }
l3(){ $VG key 317 100 0 >/dev/null 2>&1; sleep 1.2; }
swipe_n(){ grep -ac '^SWIPE ' "$HL" 2>/dev/null; }
wheel_n(){ grep -ac '^WHEEL' "$HL" 2>/dev/null; }
modes(){ logcat -d -s DexPad 2>/dev/null | grep -a 'hold-scroll' | sed 's/^.*DexPad *: //' | tail -2 | tr '\n' '|'; }
PY=-1; HS=0
ui(){ timeout 12 uiautomator dump /sdcard/v167.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v167.xml > /sdcard/v167.lines 2>/dev/null; }
scroll_metrics(){ PY=-1; HS=0; local n l b x1 y1 x2 y2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v167.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2-x1)); if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
}

# ---------------------------------------------------------------- 0 基线
sec "0 基线（v1.67 release 字节）"
wake; pin
APKH=$(sha256sum "$(pm path $PKG | sed 's/package://')" 2>/dev/null | awk '{print $1}')
HELH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | awk '{print $1}')
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | awk '{print $1}')
VER=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//'); VC=$(dumpsys package $PKG | grep -m1 versionCode | sed 's/.*versionCode=//;s/ .*//')
MODPROP=$(grep -E '^(version|versionCode)=' /data/adb/modules/gpm_dex/module.prop | tr '\n' ' ')
L "  apk=$APKH"; L "  helper=$HELH module=$MODH"; L "  version=$VER/$VC  module.prop=$MODPROP"
L "  vtouch=$(vt) prefs=$(cat "$(prefs_path)" 2>/dev/null | tr -d '\n' | sed 's/  */ /g' | cut -c1-260)"
if [ "$APKH" = "$EXPECT_APK" ]; then ck V167-APK "设备 base.apk == 发布 dexpad-v1.67.apk $EXPECT_APK" "$APKH" PASS
else ck V167-APK "设备 base.apk == 发布 dexpad-v1.67.apk" "$APKH" FAIL "pm path $PKG"; fi
if [ "$HELH" = "$EXPECT_HELPER" ] && [ "$HELH" = "$MODH" ]; then ck V167-HELPER "助手 gpm==模块==$EXPECT_HELPER" "$HELH / $MODH" PASS
else ck V167-HELPER "助手 gpm==模块==发布哈希" "$HELH / $MODH" FAIL "sha256sum"; fi
if [ "$VER" = "1.67" ] && [ "$VC" = "69" ] && echo "$MODPROP" | grep -q 'version=v1.67' && echo "$MODPROP" | grep -q 'versionCode=69'; then
  ck V167-VER "versionName=1.67 / versionCode=69（module.prop v1.67/69）" "$VER/$VC | $MODPROP" PASS
else ck V167-VER "versionName=1.67 / versionCode=69" "$VER/$VC | $MODPROP" FAIL "dumpsys package $PKG"; fi
ASZ=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)
ROT=$(settings get system user_rotation); ACC=$(settings get system accelerometer_rotation)
if [ "$ROT" = "1" ] && [ "$ACC" = "0" ] && [ "$ASZ" = "2560x1600" ]; then
  ck V167-LAND "默认横屏：user_rotation=1 accel=0 app=2560x1600（display rotation 1）" "rot=$ROT accel=$ACC app=$ASZ" PASS
else ck V167-LAND "默认横屏" "rot=$ROT accel=$ACC app=$ASZ" FAIL "settings/dumpsys"; fi

# ---------------------------------------------------------------- A 触屏模式（默认 vtouch=true）
sec "A 触屏模式（v_touch_scroll=true）：LB/RB 只出滑动，不出滚轮"
set_vt true >/dev/null 2>&1
starts; l3
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.0   # 下滚留出 LB 空间
for btn in LB RB; do
  : > "$HL"; logcat -c
  ui; scroll_metrics; py0=$PY
  if [ "$btn" = "LB" ]; then $VG key 310 1500 400 >/dev/null 2>&1; else $VG key 311 1500 400 >/dev/null 2>&1; fi
  sleep 1.4
  ui; scroll_metrics; dpy=$((py0 - PY)); [ "$dpy" -lt 0 ] && dpy=$((-dpy))
  S=$(swipe_n); W=$(wheel_n); MD=$(modes)
  L "  $btn: SWIPE=$S WHEEL=$W dPY=$dpy mode=[$MD]"
  if [ "$S" -ge 5 ] && [ "$W" -eq 0 ] && echo "$MD" | grep -q 'mode=swipe'; then
    ck "V167-$btn-SWIPE" "$btn 按住 1.5s：SWIPE≥5 且 WHEEL=0 且 mode=swipe（同按内不混）" "SWIPE=$S WHEEL=$W dPY=$dpy | $MD" PASS
  else
    ck "V167-$btn-SWIPE" "$btn 按住 1.5s：SWIPE≥5 且 WHEEL=0 且 mode=swipe" "SWIPE=$S WHEEL=$W dPY=$dpy | $MD" FAIL "vgpad key 310/311 1500"
  fi
  [ "$btn" = "RB" ] && ck V167-$btn-MOVE "$btn 触屏模式内容确实滚动 dPY>0" \
    "dPY=$dpy PY $py0->$PY" "$([ "$dpy" -gt 0 ] && echo PASS || echo FAIL)" "vgpad key 311 1500"
done

# ---------------------------------------------------------------- B 滚轮模式（prefs 改 v_touch_scroll=false + 重启引擎）
sec "B 滚轮模式（v_touch_scroll=false，prefs 直改 + 重启引擎）：LB/RB 只出滚轮"
if set_vt false; then
  ck V167-VT-OFF "release 包上把 v_touch_scroll 设为 false 并生效（无调试广播，改 prefs+重启引擎）" "vtouch=$(vt) engine=$(pidof $PKG)" PASS
else
  ck V167-VT-OFF "release 包上把 v_touch_scroll 设为 false 并生效" "vtouch=$(vt) engine=$(pidof $PKG)" FAIL "sed prefs + am start-foreground-service"
fi
starts; l3
$VG stick 4 24000 1500 >/dev/null 2>&1; sleep 1.0
for btn in LB RB; do
  : > "$HL"; logcat -c
  if [ "$btn" = "LB" ]; then $VG key 310 1500 400 >/dev/null 2>&1; else $VG key 311 1500 400 >/dev/null 2>&1; fi
  sleep 1.4
  S=$(swipe_n); W=$(wheel_n); MD=$(modes)
  L "  $btn: SWIPE=$S WHEEL=$W mode=[$MD]"
  if [ "$W" -ge 6 ] && [ "$S" -eq 0 ] && echo "$MD" | grep -q 'mode=wheel'; then
    ck "V167-$btn-WHEEL" "$btn 按住 1.5s（滚轮模式）：WHEEL≥6 且 SWIPE=0 且 mode=wheel" "SWIPE=$S WHEEL=$W | $MD" PASS
  else
    ck "V167-$btn-WHEEL" "$btn 按住 1.5s（滚轮模式）：WHEEL≥6 且 SWIPE=0" "SWIPE=$S WHEEL=$W | $MD" FAIL "vgpad key 310/311 1500 (vt=false)"
  fi
done
# 恢复默认
set_vt true >/dev/null 2>&1
ck V167-RESTORE "恢复 v_touch_scroll=true（默认安装态）" "vtouch=$(vt) engine=$(pidof $PKG) helper=$(pidof gpminput)" "$([ "$(vt)" = "true" ] && echo PASS || echo FAIL)" "sed prefs v_touch_scroll=true"

# ---------------------------------------------------------------- C 双击文案 400ms
sec "C 双击文案（ButtonDetail）：400 ms 内"
am start -n $PKG/.ButtonDetailActivity --es button a >/dev/null 2>&1
sleep 2.2
ui
TXT=$(grep -o '连续按两下 [ABXY]（[0-9]* ms 内）时触发' /sdcard/v167.lines 2>/dev/null | head -1)
L "  ButtonDetail text=[$TXT]"
case "$TXT" in
  *400*) ck V167-DBLTEXT "ButtonDetail 双击说明为 400 ms（与 DOUBLE_WINDOW=400 一致）" "$TXT" PASS ;;
  *) ck V167-DBLTEXT "ButtonDetail 双击说明为 400 ms" "${TXT:-<not found>}" FAIL "am start -n $PKG/.ButtonDetailActivity --es button a; uiautomator dump" ;;
esac

# ---------------------------------------------------------------- restore
sec "RESTORE"
am force-stop $PKG >/dev/null 2>&1; sleep 0.8
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
starts
L "  restored: helper=$(pidof gpminput) engine=$(pidof $PKG) vtouch=$(vt) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) app=$(dumpsys window displays 2>/dev/null | sed -n 's/.*app=\([0-9]*x[0-9]*\).*/\1/p' | head -1)"
L ""
L "PASS=$PASS FAIL=$FAIL FAILED=[$FAILED]"
echo "PASS=$PASS FAIL=$FAIL" >> "$RES"
[ "$FAIL" -eq 0 ]
