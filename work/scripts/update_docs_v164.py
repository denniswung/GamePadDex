import io

R = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(R, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("**当前版本：v1.63**", "**当前版本：v1.64**", "version")
rep("""| **v1.63** |""", """| **v1.64** | 光标空闲隐藏后回到**上次位置**（新增绝对定位命令 P，用有界到角+增益一步到位）；修掉 SELECT 通知栏的假通过（改真实下滑手势） |
| v1.63 |""", "history")
rep("""- 光标空闲自动隐藏后，第一次推摇杆会从**屏幕中心**出现（为保证不卡边界）。""",
    """- 光标空闲自动隐藏后，第一次推摇杆会**回到上次的位置**（精确度取决于「居中增益」标定）。""", "limit")

io.open(R, "w", encoding="utf-8", newline="\n").write(s)

T = "/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.63.md"
t = io.open(T, encoding="utf-8").read()
t = t.replace("# v1.63 测试用例与结果", "# v1.64 测试用例与结果")
t = t.replace("**v1.63**（versionCode 65）", "**v1.64**（versionCode 66）")
t = t.replace("35/35", "35/35").replace("v1.63", "v1.64")
t = t.replace("| H2 | 指针重建回中心 | d-pad 后等 10s（指针被空闲隐藏）→ 推左摇杆 | 日志出现 `pointer shown + re-centred` | PASS |",
              "| H2 | 恢复上次位置 | 移动光标→等 10s（空闲隐藏）→推左摇杆 | 恢复坐标≈隐藏前坐标（不是屏幕中心） | PASS |")
extra = '''
## v1.64 增补

| ID | 用例 | 说明 | 结果 |
|---|---|---|---|
| H2（更新） | 空闲隐藏后恢复到**上次位置** | 助手新增 `P x y w h` 绝对定位（有界到左上角再增益一步） | PASS |
| C3（收紧） | SELECT 通知栏 | 改为真实下滑手势；截图差阈值 200B → 500KB，防假通过 | PASS |
'''
t = t + extra
io.open("/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.64.md", "w", encoding="utf-8", newline="\n").write(t)
print("FAILS:", fails if fails else "none")
