p = 'work/docs/HELPER-v169.md'
s = open(p, encoding='utf-8').read()
idx = s.index('## 9. t61')
new = '''## 9. t61 复核：SCR-022 / d/m/e / 垂直滚轮 / MIX（测试通道限制）

**结论：控制通道侧可证项已证；应用端未接收属测试通道限制（原因未定，不作产品结论）。
发布字节保持 `b806f39b…`，不做任何改动。**

### 9.1 已证

- **翻页**：padtest pager 区 `H 8` → `横向 scrollX 0→512`（翻页机制本身可用）。
- **控制通道 `d/m/e`**：三条独立连接 → `DRAG up display=0 x=1280,y=600 frames=20 emitted=20 dur=1050ms`；
  helper pid 稳定、无 SIGPIPE。
- **垂直滚轮 `S 8`**：helper 日志 `WHEEL 8 h=0` 已发。

### 9.2 未证 / 限制

- **控制通道注入的触摸事件，应用端未接收**：padtest `后端统计：手势滑动 0 次 · 滚轮 0 次`、固定区 `touch=0`，
  拖拽后 offset/scrollX 不变；**原因未定，不作产品结论**。
  产品路径（引擎发 `d/m/e`）在 v1.68 发布字节上已验证（padtest PY 1415→0、PiliPlus 1623px），
  本轮**没有**“引擎路径也失效”的证据。
- **padtest 不提供可读 offset**（UI dump 中 offset 常为 0/不可读），MIX 组仍缺可量化读数。
- 试验记录：给 `drag_down` 补 `BTN_TOUCH 1` 未改变投递，已回退（哈希回到 `b806f39b`）。

### 9.3 状态

发布字节 `b806f39b…`（852960 B）三处一致，不做任何改动；t43/t45 按此绑定发布。
DeX/外接屏触摸路由如以后要做，单独开任务（属新功能/兼容性，不在本轮范围）。
'''
s = s[:idx] + new
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('doc §9 updated')
