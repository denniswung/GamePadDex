import io
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
lines = io.open(E, encoding="utf-8").read().split("\n")
start = None
for i, l in enumerate(lines):
    if "for (k in deferredSingles.keys.toList())" in l:
        start = i
        break
assert start is not None
# 找到这个 for 之后、紧接着的 `val nowH` 行，替换 start..nowH-1
end = None
for j in range(start, start + 20):
    if "val nowH" in lines[j]:
        end = j
        break
assert end is not None, "nowH not found"
new = [
    "            for (k in deferredSingles.keys.toList()) {",
    "                if (k !in STICK_MODIFIERS) continue",
    "                if (mixConsumed.add(k)) {",
    '                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")',
    "                }",
    "            }",
    '            if ("x" in STICK_MODIFIERS) {',
    '                pendingDowns.remove("x")?.let { handler.removeCallbacks(it) }',
    '                lastDownAt["x"] = 0L',
    "            }",
    "        }",
]
lines[start:end] = new
io.open(E, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("ok")
