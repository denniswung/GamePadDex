import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old_v = '''            if (ny != 0f) {
                val now = SystemClock.elapsedRealtime()
                if (vSwipeArmed && now >= vSwipeCooldownUntil) {
                    vSwipeArmed = false'''
new_v = '''            if (ny != 0f) {
                val now = SystemClock.elapsedRealtime()
                // holding the stick keeps paging: one drag every swipeRepeatMs
                if (now >= vSwipeCooldownUntil) {
                    vSwipeArmed = false'''
assert old_v in src
src = src.replace(old_v, new_v, 1)

old_v2 = '''                    vSwipeCooldownUntil = now + 260 + 200'''
new_v2 = '''                    vSwipeCooldownUntil = now + swipeRepeatMs()'''
assert old_v2 in src
src = src.replace(old_v2, new_v2, 1)

old_v3 = '''            } else if (SystemClock.elapsedRealtime() >= vSwipeCooldownUntil) {
                vSwipeArmed = true
            }'''
new_v3 = '''            } else if (SystemClock.elapsedRealtime() >= vSwipeCooldownUntil) {
                vSwipeArmed = true
            }'''
assert old_v3 in src

old_h = '''            if (hSwipeArmed && SystemClock.elapsedRealtime() >= swipeCooldownUntil) {
                hSwipeArmed = false
                swipeStep(if (nx > 0) -1 else 1)
            }'''
new_h = '''            val nowH = SystemClock.elapsedRealtime()
            if (nowH >= swipeCooldownUntil) {
                hSwipeArmed = false
                swipeStep(if (nx > 0) -1 else 1)
                swipeCooldownUntil = nowH + swipeRepeatMs()
            }'''
assert old_h in src
src = src.replace(old_h, new_h, 1)

# helper next to swipeStep
old_helper = '''    private fun swipeStep(dir: Int) = doSwipe(false, dir)'''
new_helper = '''    private fun swipeStep(dir: Int) = doSwipe(false, dir)

    /** repeat interval while the stick stays deflected (continuous paging) */
    private fun swipeRepeatMs(): Long =
        (620L - prefs.scrollSpeed * 30L).coerceIn(260L, 700L)'''
assert old_helper in src
src = src.replace(old_helper, new_helper, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
