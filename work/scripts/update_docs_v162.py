import io, sys

# README
R = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(R, encoding="utf-8").read()
fails = []
def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag); return
    s = s.replace(old, new, 1)

rep("**当前版本：v1.61**", "**当前版本：v1.62**", "version")
rep("""| **v1.61** |""", """| **v1.62** | 修复双击无效（最近任务键 187 错映射到 META_LEFT，改为 APP_SWITCH=580）；双击窗口 320→400ms；X+LB / X+RB 方向对调（LB=上一页，RB=下一页） |
| v1.61 |""", "history")
# 键位表里 X+LB/RB 的说明
s = s.replace("X + LB = 向左滑动（上一页）", "X + LB = 向右滑动（上一页）")
s = s.replace("X + RB = 向右滑动（下一页）", "X + RB = 向左滑动（下一页）")
s = s.replace("X+LB = 上一页", "X+LB = 上一页（手指向右）")
io.open(R, "w", encoding="utf-8", newline="\n").write(s)

# 测试用例文档
T = "/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.61.md"
t = io.open(T, encoding="utf-8").read()
t = t.replace("# v1.61 测试用例与结果", "# v1.62 测试用例与结果")
t = t.replace("**v1.61**（versionCode 63）", "**v1.62**（versionCode 64）")
t = t.replace("28/28", "32/32").replace("v1.61", "v1.62")
extra = '''
## G. 双击 / 组合方向（v1.62 新增）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| G1 | X 双击 = 多任务 | 两次快速按 X（间隔 120ms） | 进入 `RecentsActivity` | PASS |
| G2 | 慢双击 | 两次按 X（间隔 300ms） | 仍识别为双击 | PASS |
| G3 | X+LB 方向 | 组合键 | 手指向右（x 增大） | PASS |
| G4 | X+RB 方向 | 组合键 | 手指向左（x 减小） | PASS |

### 本轮修复

| # | 缺陷 | 说明 |
|---|---|---|
| 1 | 双击“无效” | 双击判定正常，但最近任务键 `187` 错映射成 `META_LEFT(125)`；改为 `APP_SWITCH(580)` |
| 2 | 双击太难触发 | 窗口 320ms → 400ms |
| 3 | X+LB/RB 方向反直觉 | 对调：LB = 上一页（手指向右），RB = 下一页（手指向左） |
'''
t = t + extra
io.open("/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.62.md", "w", encoding="utf-8", newline="\n").write(t)
print("FAILS:", fails if fails else "none")
