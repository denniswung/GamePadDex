import io

P = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v160_auto_suite.sh"
s = io.open(P, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 1) clean_prefs 清掉所有测试写入项（btn_/par_/left_touch/mix_ 全部）
rep('''clean_prefs(){ XML=$(xmlp); awk '!/name="btn_y"/ && !/name="par_y"/ && !/name="left_touch"/ && !/name="btn_a"/ && !/name="mix_0_/' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }''',
    '''clean_prefs(){ XML=$(xmlp); awk '!/name="(btn_|par_|left_touch|mix_|combo_|dbl_|lng_)/' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }''', "clean_prefs")

# 2) H 段删掉全部 mix 槽（避免旧槽抢先匹配）
rep("svc_del_keys 'name=\"mix_(0|1|9|11|12)_'",
    "svc_del_keys 'name=\"mix_'", "H-del1")
rep("svc_del_keys 'name=\"mix_(0|1|9|10|11|12)_'",
    "svc_del_keys 'name=\"mix_'", "H-del2")

# 3) C3：先保证屏幕亮（截图太小=黑屏，反复唤醒）
rep('''wake; sleep 1.2
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
screencap -p /data/local/tmp/n0.png 2>/dev/null''',
    '''wake; sleep 1.2
i=0
while [ $i -lt 4 ]; do
  input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  wm dismiss-keyguard >/dev/null 2>&1
  sleep 0.8
  screencap -p /data/local/tmp/n0.png 2>/dev/null
  [ "$(wc -c < /data/local/tmp/n0.png)" -gt 100000 ] && break
  i=$((i+1))
done
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
wake; sleep 0.4
screencap -p /data/local/tmp/n0.png 2>/dev/null''', "C3")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
