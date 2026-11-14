import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/README.md"
s = io.open(P, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


rep("**当前版本：v1.59**", "**当前版本：v1.60**", "version")

rep("""| **v1.59** |""", """| **v1.60** | 修复 HOME/返回/音量/静音/截图/通知栏之前其实注入失败（input 在 root 域 rc=512 → 改进程内 uinput）；主屏改用 KEY_HOMEPAGE；横向翻页方向修正；新增专用测试台 AutoTestActivity + 24 条自动化用例（全部通过） |
| v1.59 |""", "history")

rep("""## 7. 测试台（project/padtest）""",
"""## 7. 测试台（project/padtest）

> v1.60 起新增 **`AutoTestActivity`（自动化测试台）**：页面自己判断每个动作是否真的生效
> （指针移动/点击/长按/方向键焦点/滚动/双指缩放/键盘组合/返回键/触摸点击），
> 结果写到 `files/auto-report.json`，配合 `work/scripts/v160_auto_suite.sh` 可一键跑完 24 条用例。
> 详细用例：[docs/TEST-CASES-v1.60.md](docs/TEST-CASES-v1.60.md)。
""", "testapp")

io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
