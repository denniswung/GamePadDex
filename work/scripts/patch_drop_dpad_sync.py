import io
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
lines = io.open(E, encoding="utf-8").read().split("\n")
start = None
for i, l in enumerate(lines):
    if "keep the helper's d-pad forwarding in sync" in l:
        start = i
        break
assert start is not None
end = None
for j in range(start, start + 40):
    if lines[j].strip() == "}" and "if (ticks % 250" in lines[j - 12] if j >= 12 else False:
        pass
# 精确定位：从 start 起找到 `        }` 结束的 if 块（第一个缩进为 8 空格的单独 }）
for j in range(start, start + 40):
    if lines[j] == "        }":
        end = j
        break
assert end is not None, "end not found"
new = [
    "        // d-pad 统一走 App（软件在虚拟控制器层之上）：助手不再自己原生转发，",
    "        // 普通方向键与 X+方向键 只是 App 里的两种分支，互不抢占。",
]
lines[start:end + 1] = new
io.open(E, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("ok")
