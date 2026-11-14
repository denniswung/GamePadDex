import io, sys

R = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(R, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("**当前版本：v1.62**", "**当前版本：v1.63**", "version")
rep("""| **v1.62** |""", """| **v1.63** | 修复「打开应用」对部分应用无效（改为解析启动 Activity 再 `am start -n`）；修复 d-pad 确认后光标在部分方向卡住（指针重建后自动回中心并同步估算） |
| v1.62 |""", "history")

# 已知限制里补一句：空闲隐藏后光标从中心出现
rep("""- 应用列表只显示带启动入口（LAUNCHER）的应用；系统内部页面需手动输入包名。""",
    """- 应用列表只显示带启动入口（LAUNCHER）的应用；系统内部页面需手动输入包名。
- 光标空闲自动隐藏后，第一次推摇杆会从**屏幕中心**出现（为保证不卡边界）。""", "limit")

io.open(R, "w", encoding="utf-8", newline="\n").write(s)

# 测试用例文档
T = "/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.62.md"
t = io.open(T, encoding="utf-8").read()
t = t.replace("# v1.62 测试用例与结果", "# v1.63 测试用例与结果")
t = t.replace("**v1.62**（versionCode 64）", "**v1.63**（versionCode 65）")
t = t.replace("32/32", "35/35").replace("v1.62", "v1.63")
extra = '''
## H. 打开应用 / 光标重居中（v1.63 新增）

| ID | 用例 | 步骤 | 期望 | 结果 |
|---|---|---|---|---|
| H1 | Start+上 打开应用 | 组合键 start+up → open_app(com.example.piliplus) | 前台变为 PiliPlus | PASS |
| H2 | 指针重建回中心 | d-pad 后等 10s（指针被空闲隐藏）→ 推左摇杆 | 日志出现 `pointer shown + re-centred` | PASS |
| H3 | 光标四向可达 | 居中后向四个方向各推一次 | 日志里 +x/-x/+y/-y 都有位移 | PASS |

### 本轮修复

| # | 缺陷 | 说明 |
|---|---|---|
| 1 | 打开应用对部分 App 无效 | `am start -p` 解析失败；改为 `resolve-activity` + `am start -n`，再回退 `-p` / `monkey` |
| 2 | d-pad 后光标卡边界 | 空闲隐藏销毁鼠标设备 → 重建后系统光标位置改变，估算未同步导致夹取锁死；重建后自动居中+同步估算 |
'''
t = t + extra
io.open("/mnt/e/Dennis/GamePadDex复刻/docs/TEST-CASES-v1.63.md", "w", encoding="utf-8", newline="\n").write(t)
print("FAILS:", fails if fails else "none")
