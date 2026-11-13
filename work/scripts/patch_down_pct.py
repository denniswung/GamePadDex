import sys, io

path = sys.argv[1]
src = io.open(path, encoding="utf-8").read()

old = '''                    val dist = when {
                        launcher -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        feed -> (h * 0.30f).toInt().coerceIn(320, 1000)
                        else -> (h * 0.35f).toInt().coerceIn(360, 1200)
                    }
                    val down = ny <= 0
                    val pct = when {
                        launcher -> if (down) 12 else 88
                        short -> if (down) 35 else 65
                        else -> if (down) 30 else 70
                    }
                    // feeds snap one item per swipe; other apps use a long slow
                    // drag repeated back-to-back so the content moves smoothly
                    val ms = when {
                        launcher -> 200
                        feed -> 150
                        else -> 450
                    }'''
new = '''                    val down = ny <= 0
                    val dist = when {
                        launcher -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        feed -> (h * 0.30f).toInt().coerceIn(320, 1000)
                        down -> (h * 0.45f).toInt().coerceIn(320, 1200)
                        else -> (h * 0.35f).toInt().coerceIn(360, 1200)
                    }
                    val pct = when {
                        launcher -> if (down) 3 else 88
                        feed -> if (down) 35 else 65
                        down -> 3          // pull-down: shade needs the top edge
                        else -> 65
                    }
                    // feeds snap one item per swipe; pulling down is a single
                    // shade gesture; scrolling up drags slowly and repeats
                    val ms = when {
                        launcher -> 200
                        feed -> 150
                        down -> 200
                        else -> 450
                    }'''
assert old in src
src = src.replace(old, new, 1)

old2 = '''                    vSwipeCooldownUntil = now + when {
                        launcher -> swipeRepeatMs()   // one drawer step per push
                        feed -> swipeRepeatMs()       // one video per swipe
                        else -> ms + 40L              // continuous: no idle gap
                    }'''
new2 = '''                    vSwipeCooldownUntil = now + when {
                        launcher -> swipeRepeatMs()   // one drawer step per push
                        feed -> swipeRepeatMs()       // one video per swipe
                        down -> swipeRepeatMs()       // one shade pull per push
                        else -> ms + 40L              // continuous: no idle gap
                    }'''
assert old2 in src
src = src.replace(old2, new2, 1)

io.open(path, "w", encoding="utf-8", newline="\n").write(src)
print("ok")
