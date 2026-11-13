import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace('''                    Log.i(TAG, "titlebar cand cls=" + n.className + " desc=" + n.contentDescription +
                        " text=" + n.text + " bounds=" + rect)''',
'''                    Log.i(TAG, "titlebar cand cls=${n.className} desc=${n.contentDescription} text=${n.text} bounds=$rect")''', 1)
s = s.replace('''        Log.i(TAG, "dex fullscreen: clicking " + pick.className + " desc=" + pick.contentDescription +
            " bounds=" + rect + " total=" + cands.size)''',
'''        Log.i(TAG, "dex fullscreen: clicking ${pick.className} desc=${pick.contentDescription} bounds=$rect total=${cands.size}")''', 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("fixed interpolation")