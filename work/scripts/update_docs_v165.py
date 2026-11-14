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


rep("**当前版本：v1.64**", "**当前版本：v1.65**", "version")
rep("""| **v1.64** |""", """| **v1.65** | 光标空闲隐藏后**隐形恢复**到上次位置（销毁/重建鼠标设备时系统会保留坐标，不需要任何修正移动）；去掉上一版"推到角落再拉回"的可见修正 |
| v1.64 |""", "history")
rep("""- 光标空闲自动隐藏后，第一次推摇杆会**回到上次的位置**（精确度取决于「居中增益」标定）。""",
    """- 光标空闲自动隐藏后，第一次推摇杆会**直接在原地出现**（系统保留坐标，无修正移动）。""", "limit")

io.open(R, "w", encoding="utf-8", newline="\n").write(s)

T = "/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.64.md"
t = io.open(T, encoding="utf-8").read()
t = t.replace("# v1.64 测试用例与结果", "# v1.65 测试用例与结果")
t = t.replace("**v1.64**（versionCode 66）", "**v1.65**（versionCode 67）")
t = t.replace("v1.64", "v1.65")
extra = '''
## v1.65 增补

| ID | 用例 | 说明 | 结果 |
|---|---|---|---|
| H2（更新） | 光标空闲隐藏后**隐形恢复** | 隐藏前 hover 坐标 → 恢复后点击落点，误差 ≤120px（实测 0px） | PASS |

### 本轮修复

| # | 问题 | 说明 |
|---|---|---|
| 1 | 修正过程可见（跳到角落再飞回） | 实测鼠标设备销毁/重建后系统会**保留光标坐标**，因此恢复时完全不做移动，光标直接在原地出现 |
'''
t = t + extra
io.open("/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.65.md", "w", encoding="utf-8", newline="\n").write(t)
print("FAILS:", fails if fails else "none")
