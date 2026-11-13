import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''                    val feed = topPkg == "com.ss.android.ugc.aweme" ||
                        topPkg == "com.phoenix.read" || topPkg == "com.example.piliplus"
                    val launcher = topPkg == "app.lawnchair"
                    val short = feed || launcher'''
new = '''                    val feed = topPkg == "com.ss.android.ugc.aweme" ||
                        topPkg == "com.phoenix.read" || topPkg == "com.example.piliplus"
                    val launcher = topPkg == "app.lawnchair"
                    val short = feed || launcher'''
assert old in src

# distance / pct / ms: non-feed apps get a long, slow drag for continuous motion
old_d = '''                    val dist = when {
                        launcher -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        feed -> (h * 0.30f).toInt().coerceIn(320, 1000)
                        else -> (h * 0.5f).toInt().coerceIn(420, 1800)
                    }'''
new_d = '''                    val dist = when {
                        launcher -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        feed -> (h * 0.30f).toInt().coerceIn(320, 1000)
                        else -> (h * 0.35f).toInt().coerceIn(360, 1200)
                    }'''
assert old_d in src
src = src.replace(old_d, new_d, 1)

old_ms = '''                    val ms = if (feed) 150 else 200'''
new_ms = '''                    // feeds snap one item per swipe; other apps use a long slow
                    // drag repeated back-to-back so the content moves smoothly
                    val ms = when {
                        launcher -> 200
                        feed -> 150
                        else -> 450
                    }'''
assert old_ms in src
src = src.replace(old_ms, new_ms, 1)

old_cd = '''                    vSwipeCooldownUntil = now + swipeRepeatMs()'''
new_cd = '''                    vSwipeCooldownUntil = now + when {
                        launcher -> swipeRepeatMs()   // one drawer step per push
                        feed -> swipeRepeatMs()       // one video per swipe
                        else -> ms + 40L              // continuous: no idle gap
                    }'''
assert old_cd in src
src = src.replace(old_cd, new_cd, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
