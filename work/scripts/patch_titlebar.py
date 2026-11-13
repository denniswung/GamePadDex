import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"
sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()

if "fun dexTitlebarCandidates" not in s:
    block = '''
    // ---------------- DeX titlebar control (accessibility nodes) ----------------
    private fun collectClickable(n: AccessibilityNodeInfo?, out: MutableList<AccessibilityNodeInfo>, depth: Int) {
        if (n == null || depth > 12) return
        if (n.isClickable && n.isVisibleToUser) out.add(n)
        for (i in 0 until n.childCount) {
            collectClickable(n.getChild(i), out, depth + 1)
        }
    }

    /** clickable nodes in the DeX window titlebar strip, right to left */
    fun dexTitlebarCandidates(): List<AccessibilityNodeInfo> {
        val target = targetDisplayId()
        val result = ArrayList<AccessibilityNodeInfo>()
        val ws = try { windows } catch (t: Throwable) { null } ?: return result
        for (w in ws) {
            if (w.displayId != target) continue
            if (w.type != AccessibilityWindowInfo.TYPE_APPLICATION) continue
            val r = w.root ?: continue
            val all = ArrayList<AccessibilityNodeInfo>()
            collectClickable(r, all, 0)
            val rect = android.graphics.Rect()
            for (n in all) {
                n.getBoundsInScreen(rect)
                if (rect.top < 160 && rect.height() in 1..120 && rect.left > 0) {
                    Log.i(TAG, "titlebar cand cls=" + n.className + " desc=" + n.contentDescription +
                        " text=" + n.text + " bounds=" + rect)
                    result.add(n)
                }
            }
            break
        }
        result.sortByDescending { n ->
            val rect = android.graphics.Rect(); n.getBoundsInScreen(rect); rect.left
        }
        return result
    }

    /** click the fullscreen / maximize button in the DeX titlebar */
    fun dexFullscreenClick(): Boolean {
        val cands = dexTitlebarCandidates()
        if (cands.isEmpty()) {
            Log.w(TAG, "dex fullscreen: no titlebar nodes")
            return false
        }
        // prefer an explicit fullscreen / maximize description
        val byName = cands.firstOrNull { n ->
            val d = ((n.contentDescription ?: "") + " " + (n.text ?: "")).lowercase()
            d.contains("fullscreen") || d.contains("full screen") || d.contains("全屏") ||
                d.contains("maximize") || d.contains("最大化")
        }
        val pick = byName ?: cands.getOrNull(1) ?: cands.first()
        val rect = android.graphics.Rect(); pick.getBoundsInScreen(rect)
        Log.i(TAG, "dex fullscreen: clicking " + pick.className + " desc=" + pick.contentDescription +
            " bounds=" + rect + " total=" + cands.size)
        return pick.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

'''
    s = s.replace("    /** runs a mapped action, including the pseudo actions handled here */",
                  block + "    /** runs a mapped action, including the pseudo actions handled here */", 1)
    # route the action: titlebar click first, am relaunch as fallback
    s = s.replace('''            "dex_fullscreen" -> {
                val disp = targetDisplayId()
                val comp = lastFgComponent
                if (comp != null) {
                    root?.relaunchFullscreen(disp, comp)
                    Log.i(TAG, "dex fullscreen " + comp + " on display " + disp)
                } else {
                    Log.w(TAG, "dex fullscreen: no foreground component yet")
                }
            }''',
'''            "dex_fullscreen" -> {
                val ok = dexFullscreenClick()
                Log.i(TAG, "dex_fullscreen via titlebar -> " + ok)
                if (!ok) {
                    val disp = targetDisplayId()
                    val comp = lastFgComponent
                    if (comp != null) {
                        root?.relaunchFullscreen(disp, comp)
                        Log.i(TAG, "dex fullscreen fallback " + comp + " on display " + disp)
                    }
                }
            }''', 1)
    if "import android.view.accessibility.AccessibilityWindowInfo" not in s:
        s = s.replace("import android.view.accessibility.AccessibilityEvent",
                      "import android.view.accessibility.AccessibilityEvent\nimport android.view.accessibility.AccessibilityNodeInfo\nimport android.view.accessibility.AccessibilityWindowInfo", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("titlebar click added")