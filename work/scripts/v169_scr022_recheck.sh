#!/system/bin/sh
# SCR-022 复测（t53 修复右摇杆横向锚点后运行）
# 口径：P(1282,1511)+stick 2s → scrollX≥400 = PASS；P(1282,800)+stick → scrollX 不变；X+RB 0→512 为基准
S=/data/adb/gpm/gpmctl.sock; G=/data/local/tmp/gpmctl; PKG=com.dennis.dexpad; PAD=com.dennis.padtest; VG=/data/local/tmp/vgpad
OUT=/data/local/tmp/v169_scr022.log; : > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
dump(){ am force-stop $PKG >/dev/null 2>&1; sleep 1.0
  rm -f /sdcard/x.xml /sdcard/x.lines
  timeout 15 uiautomator dump /sdcard/x.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/x.xml > /sdcard/x.lines 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0; while [ $i -lt 12 ]; do i=$((i+1)); pidof $PKG >/dev/null 2>&1 && break; sleep 0.5; done; sleep 2.5; }
sx(){ grep -o 'scrollX=[0-9]*' /sdcard/x.lines | head -1 | sed 's/scrollX=//'; }
hswipe(){ logcat -d -s DexPad 2>/dev/null | grep -a 'hswipe' | tail -1 | sed 's/^.*DexPad *: //'; }
anchor_ok(){ # $1=target_x $2=target_y $3=hswipe line
  echo "$3" | grep -q "anchor=$1,$2" && return 0
  echo "$3" | sed -n "s/.*anchor=\([0-9]*\),\([0-9]*\).*/\1 \2/p" | awk -v tx="$1" -v ty="$2" "{dx=\$1-tx; dy=\$2-ty; if(dx<0)dx=-dx; if(dy<0)dy=-dy; exit !(dx<=8 && dy<=8)}"
}
ctl_ok(){ $G $S '?' 2>/dev/null | grep -q 'SELFTEST begin'; }
if ! ctl_ok; then L "BLOCKED(helper-restarted) helper=$(pidof gpminput)"; exit 3; fi
L "helper=$(pidof gpminput) selftest=ok"
am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.5; cmd statusbar collapse >/dev/null 2>&1
# 先回到第 1 页（X+LB 连按 3 次），再取基准
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 0.8
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 0.8
dump; base=$(sx); L "base scrollX=$base (回第1页后)"
# 1) 指针在分页区 + 右摇杆横向 2s
$G $S 'j' >/dev/null; $G $S 'P 1282 1511 2560 1600' >/dev/null; sleep 0.4
L "cursor: $($G $S 'c' | grep -a '^CURSOR ')"
$VG stick 3 -30000 2000 >/dev/null 2>&1; sleep 0.8
dump; s1=$(sx); hs1=$(hswipe); L "P(1511)+stick-left2s → scrollX=$s1 (期望 ≥400) hswipe=[$hs1]"
if ! anchor_ok 1282 1511 "$hs1"; then L "WARN: hswipe anchor 与 P 目标不匹配，scrollX 变化可能非锚点所致 [$hs1]"; fi
$G $S 'j' >/dev/null; $G $S 'P 1282 1511 2560 1600' >/dev/null; sleep 0.4
$VG stick 3 30000 2000 >/dev/null 2>&1; sleep 0.8
dump; s2=$(sx); L "P(1511)+stick-right2s → scrollX=$s2"
# 2) 指针在列表 + 右摇杆横向 → 分页不得变
$G $S 'j' >/dev/null; $G $S 'P 1282 800 2560 1600' >/dev/null; sleep 0.4
$VG stick 3 -30000 2000 >/dev/null 2>&1; sleep 0.8
dump; s3=$(sx); L "P(800)+stick-left2s → scrollX=$s3 (期望不变)"
# 3) X+RB 基准
$G $S 'j' >/dev/null; $G $S 'P 1282 1511 2560 1600' >/dev/null; sleep 0.4
$VG combo 307 311 300 2600 >/dev/null 2>&1; sleep 1.0
dump; s4=$(sx); L "X+RB → scrollX=$s4 (基准 512) hswipe=[$(hswipe)]"
anchor_ok 1282 1511 "$hs1" || { L "SCR-022 FAIL(anchor-mismatch): [$hs1]"; exit 4; }
if [ "${s1:-0}" -ge 400 ] && [ "${s2:-0}" -ge 400 ] && [ "${s3:-0}" -eq "${base:-0}" ] && [ "${s4:-0}" -ge 400 ]; then
  L "SCR-022 PASS"
else
  L "SCR-022 FAIL / 待查：$s1/$s2/$s3/$s4"
fi
