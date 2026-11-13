import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
if '"probe_windows"' not in s:
    s = s.replace('            "dex_fullscreen" -> {',
'''            "probe_windows" -> {
                val ws = try { windows } catch (t: Throwable) { null }
                Log.i(TAG, "PROBE windows=" + (ws?.size ?: -1))
                ws?.forEach { w ->
                    Log.i(TAG, "PROBE win type=" + w.type + " disp=" + w.displayId +
                        " active=" + w.isActive + " focused=" + w.isFocused + " title=" + w.title)
                }
                val activeRoot = try { rootInActiveWindow } catch (t: Throwable) { null }
                Log.i(TAG, "PROBE activeRoot=" + activeRoot?.packageName + " children=" + activeRoot?.childCount)
                val cands = dexTitlebarCandidates()
                Log.i(TAG, "PROBE titlebar candidates=" + cands.size)
            }
            "dex_fullscreen" -> {''', 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("probe_windows action added")