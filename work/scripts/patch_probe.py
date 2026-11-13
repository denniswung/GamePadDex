import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
# 1) probe: how many windows, and what is the active root
s = s.replace('''        val ws = try { windows } catch (t: Throwable) { null } ?: return result''',
'''        val ws = try { windows } catch (t: Throwable) { null }
        Log.i(TAG, "probe: windows=" + (ws?.size ?: -1))
        val activeRoot = try { rootInActiveWindow } catch (t: Throwable) { null }
        Log.i(TAG, "probe: activeRoot=" + activeRoot?.packageName + " nodes=" + activeRoot?.childCount)
        if (ws == null || ws.isEmpty()) {
            // enumerate other apps' windows is not allowed here: fall back to the
            // focused window, whose decor view carries the DeX titlebar buttons
            if (activeRoot != null) {
                val all2 = ArrayList<AccessibilityNodeInfo>()
                collectClickable(activeRoot, all2, 0)
                val rect = android.graphics.Rect()
                for (n in all2) {
                    n.getBoundsInScreen(rect)
                    if (rect.top < 160 && rect.height() in 1..120) {
                        Log.i(TAG, "focused-win cand cls=${n.className} desc=${n.contentDescription} text=${n.text} bounds=$rect")
                        result.add(n)
                    }
                }
                result.sortByDescending { n ->
                    val r2 = android.graphics.Rect(); n.getBoundsInScreen(r2); r2.left
                }
            }
            return result
        }''', 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("probe + focused-window fallback added")