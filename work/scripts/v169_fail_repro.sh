#!/system/bin/sh
# t39 FAIL 三复现：MIX-009 / LOG-001 / RPT-002 / RPT-003 / RPT-004 / BTN-001
# 输出：/data/local/tmp/v169_failrepro.log
PKG=com.dennis.dexpad; PAD=com.dennis.padtest; VG=/data/local/tmp/vgpad
OUT=/data/local/tmp/v169_failrepro.log; EVID=/data/local/tmp/v169_evidence/failrepro
mkdir -p "$EVID"; : > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
dump(){ # $1=tag
  am force-stop $PKG >/dev/null 2>&1; sleep 1.2
  rm -f /sdcard/f.xml /sdcard/f.lines
  timeout 15 uiautomator dump /sdcard/f.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/f.xml > /sdcard/f.lines 2>/dev/null
  cp /sdcard/f.lines "$EVID/$1.lines" 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  local i=0; while [ $i -lt 12 ]; do i=$((i+1)); pidof $PKG >/dev/null 2>&1 && break; sleep 0.5; done; sleep 2.5
  echo "$(wc -l < /sdcard/f.lines 2>/dev/null)"
}
pad(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.4; cmd statusbar collapse >/dev/null 2>&1; }
L "== t39 FAIL repro $(date) =="

# MIX-009: 右摇杆横向，scrollX 是否变化（3 次）
L ""
L "-- MIX-009（右摇杆横向 → 分页 scrollX）--"
i=0
while [ $i -lt 3 ]; do
  i=$((i+1)); pad; $VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
  dump m9_${i}_a >/dev/null
  hs0=$(grep -o 'text="第 [1-5] 页"' $EVID/m9_${i}_a.lines | head -1)
  $VG stick 3 -30000 1500 >/dev/null 2>&1; sleep 0.8
  dump m9_${i}_b >/dev/null
  hs1=$(grep -o 'text="第 [1-5] 页"' $EVID/m9_${i}_b.lines | head -1)
  p0=$(grep -o 'bounds="[^"]*"' $EVID/m9_${i}_a.lines | head -1)
  L "  #$i: page[$hs0]->[$hs1]"
done

# LOG-001: LogActivity dump 是否含事件行（3 次）
L ""
L "-- LOG-001（LogActivity 事件行）--"
i=0
while [ $i -lt 3 ]; do
  i=$((i+1))
  am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.LogActivity >/dev/null 2>&1; sleep 2
  n=$(dump log_$i)
  rows=$(grep -cE '^[A-Z]+/' $EVID/log_$i.lines 2>/dev/null)
  txt=$(grep -o 'text="[^"]*"' $EVID/log_$i.lines 2>/dev/null | head -5 | tr '\n' ' ')
  L "  #$i: lines=$n eventRows=$rows texts=[$txt]"
done

# RPT-002: 报告页按钮文案（3 次）
L ""
L "-- RPT-002（报告页“开始”按钮文案）--"
i=0
while [ $i -lt 3 ]; do
  i=$((i+1))
  am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ReportActivity >/dev/null 2>&1; sleep 2
  dump rpt_$i >/dev/null
  L "  #$i: $(grep -o 'text="[^"]*"' $EVID/rpt_$i.lines | head -12 | tr '\n' ' ')"
done

# RPT-003/004: 导出文件（3 次）
L ""
L "-- RPT-003/004（TXT/JSON 导出文件）--"
i=0
while [ $i -lt 3 ]; do
  i=$((i+1))
  before=$(ls /sdcard/Download/*.txt /sdcard/Download/*.json 2>/dev/null | wc -l)
  am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ReportActivity >/dev/null 2>&1; sleep 2
  dump rptx_$i >/dev/null
  # 直接点“导出报告 TXT”/“导出报告 JSON”
  for t in "导出报告 TXT" "导出报告 JSON"; do
    b=$(grep -m1 "text=\"$t\"" $EVID/rptx_$i.lines 2>/dev/null | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')
    [ -n "$b" ] && set -- $b && input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )) && sleep 1.5
  done
  after=$(ls /sdcard/Download/*.txt /sdcard/Download/*.json 2>/dev/null | wc -l)
  L "  #$i: files $before -> $after ; list=[$(ls -t /sdcard/Download/*.txt /sdcard/Download/*.json 2>/dev/null | head -3 | tr '\n' ' ')]"
done

# BTN-001: ButtonDetail 详情页文本（3 次）
L ""
L "-- BTN-001（ButtonDetailActivity 400ms 文本）--"
i=0
while [ $i -lt 3 ]; do
  i=$((i+1))
  am force-stop $PKG >/dev/null 2>&1; sleep 1
  am start -n $PKG/.ButtonDetailActivity >/dev/null 2>&1; sleep 2.5
  f=$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus=Window' | sed 's/.*u0 //;s/}.*//')
  n=$(dump btn_$i)
  has=$(grep -c '400 ms' $EVID/btn_$i.lines 2>/dev/null)
  L "  #$i: focus=$f lines=$n has400ms=$has texts=$(grep -o 'text="[^"]*"' $EVID/btn_$i.lines | head -6 | tr '\n' ' ')"
done

L ""
L "== repro done =="
