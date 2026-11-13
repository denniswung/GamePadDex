import io

# ---- KeyMachine: tolerate a missed key-up, try recent pairs for chords ----
p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/v2/KeyMachine.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace("""    private var lastReleaseAt = HashMap<String, Long>()
""", """    private var lastReleaseAt = HashMap<String, Long>()
    private val recent = ArrayDeque<Pair<String, Long>>()
""", 1)
s = s.replace("""        pressed.add(button)
        downAt[button] = SystemClock.elapsedRealtime()
""", """        pressed.add(button)
        val nowDown = SystemClock.elapsedRealtime()
        downAt[button] = nowDown
        recent.addLast(button to nowDown)
        while (recent.size > 4) recent.removeFirst()
""", 1)
s = s.replace("""        // 1) chord: newest key + the oldest still-held different key
        if (pressed.size >= 2) {
            val leader = pressed.firstOrNull { it != button }
            if (leader != null) {
                val chord = combos.resolve(leader, button)
                if (chord != null) {""", """        // 1) chord: try every recently pressed key as the leader (a missed
        // key-up must not break the pairing), newest first
        val leaders = ArrayList<String>()
        leaders.addAll(pressed.filter { it != button })
        recent.reversed().forEach { (b, t) ->
            if (b != button && nowDown - t <= 1000 && !leaders.contains(b)) leaders.add(b)
        }
        for (leader in leaders) {
            run {
                val chord = combos.resolve(leader, button)
                if (chord != null) {""", 1)
s = s.replace("""                    host.perform(chord.action, chord.value)
                    return
                }
            }
        }
""", """                    host.perform(chord.action, chord.value)
                    return
                }
            }
        }
""", 1)
# close the extra run{} loop correctly: the original block had two closing braces
io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# ---- checklist pos(): use dumpsys input hover pointer (probe is fullscreen) ----
c = "/mnt/e/Dennis/GamePadDex复刻/work/scripts/checklist_v2.sh"
t = io.open(c, encoding="utf-8").read()
old_pos = t[t.index("pos() {"):t.index("\n}", t.index("pos() {")) + 2]
new_pos = '''pos() {
    for k in 1 2 3; do
        v=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/.*at (//;s/)//')
        [ -n "$v" ] && { echo "x=${v%,*} y=${v#*,}"; return; }
        input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
        wm dismiss-keyguard >/dev/null 2>&1
        am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
        sleep 1
    done
    echo ""
}'''
t = t.replace(old_pos, new_pos)
io.open(c, "w", encoding="utf-8", newline="\n").write(t)
print("patched key machine + pos()")
