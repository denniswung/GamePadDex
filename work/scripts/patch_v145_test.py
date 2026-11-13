import io, re
p = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/v145_checklist.sh"
s = io.open(p, encoding="utf-8").read()
# real preferences live under /data/misc/<user>/prefs/<pkg> on this ROM
s = s.replace('    rm -f /data/data/$PKG/shared_prefs/dexpad.xml 2>/dev/null',
              '    rm -f /data/data/$PKG/shared_prefs/*.xml 2>/dev/null\n    rm -f /data/misc/*/prefs/$PKG/*.xml 2>/dev/null')
# v1.43 helper scans /dev/input every 2 s: always give the virtual pad time
s = re.sub(r'(/data/local/tmp/vgpad [a-z]+ (?:[0-9]+ )*?)(0)( >/dev/null 2>&1)', r'\g<1>2500\g<3>', s)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("patched")
