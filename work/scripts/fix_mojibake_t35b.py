#!/usr/bin/env python3
"""t35: rewrite mojibake comments in gpminput.c, line-by-line (line count preserved,
code text before '/*' kept byte-identical).  Binary hash must not change."""
import re
import sys

PATH = 'project/app/src/main/assets/gpminput.c'
lines = open(PATH, encoding='utf-8').read().split('\n')

# start -> (end, [text]) ; text is flattened and split across the region's lines
REPL = {
95: (95, ['绝对指针设备：只用来「一次性把指针放到指定坐标」（相对鼠标有加速度，算不准）。']),
97: (98, ['居中/绝对定位用的 raw->px 增益（可被命令 g / O 修改，用于标定）', '0 = 未标定，回落到实测出来的 g_pointer_gain']),
99: (99, ['最近一次已知的屏幕尺寸（通知栏下滑手势要用）']),
101: (101, ['最近一次解析到的前台包名（杀应用用）']),
103: (103, ['虚拟触摸屏：给「点击=触摸」和「双指缩放」用（真实触摸事件，带多点协议 B）']),
107: (107, ['static int g_pinch_dir = 0;          /* +1 放大 / -1 缩小 / 0 停止 */']),
108: (108, ['static int g_pinch_d = 60;           /* 两指参考距离 */']),
109: (109, ['static int g_pinch_x = 0, g_pinch_y = 0;   /* 缩放基准点（光标位置） */']),
251: (251, ['因此「居中」只需一条 EV_ABS，不需要猜像素增益']),
293: (296, ['非阻塞按键释放：旧代码在命令循环里 usleep(8~45ms) 才发释放，d-pad 每次点击都会把整个循环卡住 45ms',
           '现在按下立即写 uinput，释放时间登记，由主循环到期补发']),
356: (357, ['虚拟触摸屏：Android 用多点协议 B（SLOT + TRACKING_ID + POSITION）',
           'INPUT_PROP_DIRECT 让系统把它当真正的触摸板而不是鼠标']),
393: (393, ['把一个屏幕像素坐标换算成触摸设备的 0..32767 坐标']),
401: (404, ['系统给虚拟触摸面板按 90° 旋转映射（本机 DeX 横屏 2560x1600）',
           '应用 x = 1.6 * panel_y；应用 y = 1865 - 0.8325 * panel_x',
           '反解：panel_y = 0.625*x；panel_x = (1865 - y)/0.8325']),
428: (428, ['单指按下 / 抬起（点击、长按）']),
448: (448, ['双指缩放：由主循环按 8~16ms 节奏推动，按住期间连续生效']),
971: (976, ['屏幕状态 / 唤醒：dumpsys power 单次 30~80ms，绝不能在命令循环里同步跑',
           '缓存 /data/adb/gpm/wake.txt 写入 "Awake <monotonic_ms>"，主循环每 ~5s 让子进程刷新',
           'u 命令只在 mWakefulness != Awake 时注入 KEY_WAKEUP，已亮时零注入']),
1017: (1017, ['blocking mWakefulness read — only ever called from a child process']),
1043: (1044, ['每 4s 一次：缓存只用来判断「是否可能需要唤醒」，真正不确定时先探测再注入，所以 4s 粒度足够']),
1064: (1065, ['Linux KEY_WAKEUP = 143. (224 is KEY_BRIGHTNESSDOWN on Linux — the old code used it by mistake.)']),
1074: (1074, ['blocking KEY_WAKEUP pulse — only used inside a child process']),
1085: (1086, ['慢链路：必要时先探测（缓存说「亮着」但可能刚灭屏），再 KEY_WAKEUP → 兜底；永远在子进程里跑',
            'emitted=1 表示父进程已经发过 uinput KEY_WAKEUP']),
1096: (1096, ['探测优先：屏幕真的亮着就什么都不做（负例），刚灭屏则立刻补发']),
1132: (1136, ['u：点亮屏幕（摇杆大幅移动时由应用调用）。立即返回（只做文件读 + 可选的一次 uinput 写）',
            '探测/兜底都在子进程。缓存明确「非 Awake」→ 立刻注入 KEY_WAKEUP；',
            '缓存说「Awake」且很新 → 先异步探测再决定；3s 内重复请求 → 去重']),
1151: (1151, ['可能刚灭屏：先探测（子进程），真的亮着就零注入']),
1156: (1156, ['缓存缺失/过期：按「不确定」处理，注入 KEY_WAKEUP（亮屏时是空操作）']),
1163: (1163, ['主循环不再被 popen/usleep 卡住']),
1195: (1200, ['c：真实光标位置（应用闭环居中用）',
            'dumpsys input 的 CursorStatesByDisplay 按 display 分段，hoveringPointers 是 raw natural 坐标',
            'App 的 Display.getSize() 是逻辑坐标；现在按 display 分段解析，优先 display 0 的 MOUSE hover',
            '再用 viewport（orientation/logicalFrame/physicalFrame/deviceSize）换算成逻辑坐标']),
1223: (1223, ['raw natural（面板原始坐标）-> 逻辑坐标（与 InputReader 的旋转换算一致）']),
1246: (1246, ['返回 1 = 找到光标；space=1 表示已换算成逻辑坐标，0 = 只有 raw 坐标可用']),
1292: (1292, ['分组行（4 空格缩进 + displayId + " :"）："    0 :     Windows:"']),
1316: (1316, ['优先 display 0；否则第一个 MOUSE hover；再否则第一个']),
1339: (1340, ['c：真实光标位置（App 做闭环标定时用），dumpsys input 在子进程里跑，主循环零阻塞',
            '回包 CURSOR <lx> <ly> display=<id> space=logical [frame=<x,w> raw=<rx>,<ry>]，找不到为 CURSOR -1 -1 display=-1']),
1514: (1514, ['有右摇杆的手柄：Z/RZ 是扳机，按 0..1 归一（否则要按到 75% 才触发）']),
1533: (1534, ['鼠标设备可能被「空闲隐藏」销毁了：任何一次移动/点击前都确保它存在',
            '否则 App 侧状态一旦不同步，就会表现为「光标不见了/点了没反应」']),
1596: (1597, ['居中：先用多个「有界小步」把指针推到左上角（一步 -30000 会把指针甩出屏幕），再按增益一步走到屏幕中心',
            '用法：O <w> <h> <park> <rot> [gain]']),
1658: (1659, ['能否创建/注入 uinput 设备（鼠标/键盘/滚轮的能力 = uinput 节点可写）',
            '注意：不能用「虚拟鼠标当前是否已打开」当能力——空闲隐藏会销毁它，那只是运行时状态']),
1665: (1665, ['是否能枚举/抓取 /dev/input 下的手柄（能力；具体抓到几个看 CAP devices 数量）']),
1670: (1670, ['是否有手柄处于 grab 状态（INFO 用，不是能力）']),
1679: (1682, ['CAP <name> <0|1> = 能力（不是运行时状态）。能力存在=1；只有真的缺依赖才 0',
            'App 设置页把 CAP 0 显示为「缺失」，所以这里绝不能上报瞬时状态',
            'CAP devices <n> 是数量：0 = 没接手柄（如实反映），能力项另看 CAP gamepad',
            'CAP screen = 能读到屏幕状态（dumpsys power 里能解析到 mWakefulness），不是当前是否亮屏']),
1683: (1683, ['    out("CAP mouse %d", ui);                 /* 能否创建/注入 uinput 鼠标（能力） */']),
1684: (1684, ['    out("CAP kbd %d", ui);                   /* 能否创建/注入 uinput 键盘（能力） */']),
1685: (1685, ['    out("CAP wheel %d", ui);                 /* 滚轮走同一个 uinput 鼠标（能力） */']),
1694: (1694, ['    out("CAP gamepad %d", input_enum_capable());   /* 能否枚举/抓取手柄（能力） */']),
1695: (1695, ['    out("CAP devices %d", g_ndev);                 /* 数量；0 = 未接手柄（真实状态） */']),
1696: (1696, ['    /* 串行手势队列的能力 = 注入器可用（input 可执行）；busy 是运行时状态，放 INFO */']),
1705: (1707, ['最近一次的前台包名（topResumedActivity）',
            'dumpsys activity activities 要 100~300ms，放子进程；每 2s 刷新一次，避免 App 查询时同步等待']),
1723: (1723, ['缓存为空时同步查一次，保证第一次调用就有值']),
1756: (1756, ['缓存为空时同步查一次，保证第一次调用就有值']),
1785: (1785, ['最近一次滑动用到的 display/分辨率：主循环每 2s 主动刷新一次，保证被写坏的缓存（投毒）最多 2s 就被真实值覆盖']),
1791: (1795, ['任务边界缓存的由来（DIAG v166 实测 4 个坑）',
            '1) 只有一份 taskbounds.txt 时 display 0/1 互相覆盖；2) 刷新失败写 "0 0 maxX maxY"（全屏）',
            '3) 缓存永不过期；4) 刷新 fork 在 cmd_swipe 里，滑动路径要等 fork',
            '现在：按 display 分文件 taskbounds-<display>.txt，内容 "pkg x1 y1 x2 y2 w h"',
            '校验面积、分辨率、pkg==top.txt、>=120x120、mtime<=4s；主循环刷新，滑动路径只读缓存']),
1802: (1802, ['static int g_bounds_force_refresh = 0;   /* 周期刷新：绕过 mtime 节流（周期本身即节流） */']),
1803: (1804, ['最近一次滑动的 display/分辨率：主循环每 2s 主动刷新一次，保证被写坏的缓存（投毒）最多 2s 就被真实值覆盖']),
1808: (1808, ['滑动前用一次 dumpsys input 校验边界缓存（失败退全屏）']),
1826: (1826, ['    if (w != maxX || h != maxY) return 0;              /* 分辨率不匹配 */']),
1828: (1829, ['缓存里的包名和真实前台不一致（App 切换/杀进程），或者 top.txt 还没刷新，直接判无效']),
1843: (1844, ['force=1：主循环的周期刷新（周期本身已是节流，必须绕过 mtime 节流，否则投毒后的第一个 tick',
            '可能落在 mtime<2s 窗口里被丢掉，最坏要等 ~4s）；force=0：滑动路径的按需刷新（保留 2s 节流）']),
1853: (1853, ['主循环调用：真正 fork 刷新子进程；滑动路径不再付这个开销']),
1865: (1865, ['        return;                                                        /* 仅滑动路径保留 2s 节流 */']),
1905: (1906, ['手势保护窗：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」',
             '所以向下的滑动必须从保护区以下起手（这是划出状态下拉出状态栏的根因）']),
1913: (1913, ['兼容旧文件：legacy 文件只写不读（4 段格式）']),
1925: (1927, ['input swipe 每次起一条独立注入流；两条同时在飞会互相吞并（DIAG 实测：应用只收到 1 click / 0 TOUCH）',
            '这里做真正的串行注入：任意时刻最多 1 条在飞；在飞时另一轴的手势直接丢弃并记 SWIPE_DROP',
            '同轴手势进 1 深度等待队列；每条注入 start/done 成对出现，可证伪']),
2099: (2099, ['#define SWIPE_SETTLE_MS 60       /* 上一条结束后让系统处理完 UP */']),
2100: (2100, ['#define SWIPE_AXIS_GUARD_MS 90   /* 换轴保护窗：刚滑完立刻反向视为串扰 */']),
2109: (2109, ['    int tx1, tx2, ty1, ty2;      /* task 区域（夹取用） */']),
2237: (2237, ['缓存不可信：本次用全屏，刷新交给主循环（不在滑动路径 fork）']),
2242: (2243, ['方向性保护：向下的滑动必须从保护区以下起手（App 侧同理），否则会被系统当成拉通知栏']),
2277: (2278, ['手势保护区：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」',
             '所以向下的滑动必须从保护区以下起手']),
2284: (2284, ['最终夹到屏幕内：越界坐标 input 会直接丢弃整条手势']),
2437: (2437, ['真杀：am force-stop + 直接 SIGKILL 兜底（保证「确实死了」）']),
2479: (2479, ['按 *包名* 比较：一个应用可能有多个 activity 组件（设置里有几十个）',
            '组件匹配会「切」到同一个应用的另一个 activity，看起来像什么都没发生']),
2510: (2510, ['Android keycode -> Linux input code（只覆盖映射表里会用到的组合键）']),
2534: (2534, ['        case 187: return 580;  /* APP_SWITCH（多任务/最近任务） */']),
2553: (2553, ['        case 120: return 99;   /* SYSRQ (截图) */']),
2554: (2555, ['DPAD_CENTER：Samsung 上 KEY_OK(352) 不会触发确认，KEY_ENTER(28) 可以',
            '实测 KEY_SELECT 353 / KPENTER 96 也可以，取最通用的 ENTER']),
2605: (2605, ['依次按下，再逆序释放：Ctrl+Minus 这类组合才会被应用当成「按住组合」']),
2630: (2631, ['Alt+Tab via the virtual keyboard: keep ALT held while TAB is pressed, then',
            'release both — this is what the DeX app switcher expects']),
2680: (2680, ["有的版本会带 \"priority=0 ...\" 前缀，取最后一个含 '/' 的 token"]),
2736: (2737, ['居中要 ~280ms 的有界步进，放到子进程里做：命令循环不被卡住',
            '子进程继承同一个 uinput 鼠标 fd，REL 事件顺序不变']),
2779: (2781, ['杀前台：包名依次尝试 dumpsys activity / dumpsys window / 缓存',
            '然后 am force-stop（functional），再直接 SIGKILL 所有进程（兜底）']),
2798: (2798, ['最后兜底：App 上次查询到并缓存到 top.txt 里的前台包']),
2823: (2824, ['模拟电源键：优先用我们自己虚拟键盘的 KEY_POWER（内核级，不依赖 SELinux/binder）',
            '失败再退回 `input keyevent 26`；释放走主循环的延时队列，不再 usleep(40ms) 卡住命令循环']),
2830: (2830, ['电源键会翻转屏幕状态：立刻让唤醒缓存失效，下一次 u 不再误判']),
2834: (2835, ['兜底放到子进程里跑：input 在这个域里可能长时间不返回',
            '会卡住整个命令循环（表现为按键全部失灵）']),
2872: (2873, ['优先用我们自己的虚拟键盘注入（内核级，稳定）；input keyevent 在 ksu 域里',
            '返回 512（exit code 2），事件根本进不去']),
2877: (2877, ['                    key_release_later(g_kbd, lc, 8);   /* 不阻塞命令循环 */']),
2879: (2879, ['电源键（26）翻转屏幕状态：唤醒缓存立即失效']),
2882: (2882, ['没有映射的键才退回 input（子进程里跑，避免卡主循环）']),
2896: (2897, ['C <display> <androidKeyCode> ... : 组合键（Ctrl+Plus 等）',
            '不走 `input keycombination`（root 上下文里返回 512），改用 uinput 键盘按序按下/释放']),
2931: (2932, ['当前前台包名：桌面/游戏要用 d-pad 转发，而不是触摸滑动',
            '首次没有缓存时会同步 dumpsys：整个查询丢给子进程，循环不卡']),
2942: (2942, ['隐藏系统鼠标指针：销毁虚拟鼠标设备（指针图标随之消失）']),
2958: (2959, ['A <dir> [hold]  dir: 1上 2下 3左 4右',
            '由 App 决策后回写方向：走虚拟键盘的箭头键（系统会把它当成 DPAD_*），没有虚拟键盘时退回 input keyevent',
            '释放由主循环延时队列补发，不再 usleep(45ms) 卡住循环']),
2974: (2974, ['没有虚拟键盘：按住语义用 keyevent 实现不了，退化成一次点击']),
2988: (2990, ['展开通知栏：uinput 的 KEY_NOTIFICATION_CENTER 在三星上不生效，cmd statusbar 同域注入失败',
            '所以改成「从顶部边缘下滑」的真实触摸手势（和用户手指下拉通知栏完全一样）',
            '走串行手势队列，不会和滚动/翻页手势并发（并发会互相吞并成一次点击）']),
3008: (3008, ['SurfaceFlinger dump 200~600ms：子进程执行，回包 CURSOR']),
3065: (3070, ['w <pkg>：启动目标应用（后台服务自己 startActivity 会被系统拦，走 root 的 am start 才可靠）',
             '主路径固定为「resolve-activity 解析组件 + am start -n」',
             'am start -p <pkg> 对部分应用会 unable to resolve Intent（实测 PiliPlus），所以 -p 只在解析失败时做次选，并标记 fallback=pkg',
             '解析依次用 cmd package resolve-activity --brief、pm resolve-activity --brief',
             'am start 的输出里出现 "Error:" 视为失败，再退 monkey']),
3095: (3095, ['次选（不是主路径）：Intent + 包名过滤']),
3104: (3104, ['最后兜底：monkey 启动（老办法，几乎总能拉起主界面）']),
3118: (3118, ['q <w> <h> : 触摸面尺寸（像素 -> 触摸坐标）']),
3128: (3128, ['k <x> <y> <down> : 单指触摸（点击 / 长按）']),
3143: (3145, ['增益标定：g 查询 -> GAIN center=… ptr=…；g ? 同上（显式查询）',
             'g <center> 设置居中增益（向后兼容旧调用）；g <center> <ptr> 同时设置 REL->px 实测增益',
             'ptr 增益在 center 未标定时作为默认值，所以标定过的值一定生效']),
3153: (3153, ['            if (g1 == 0.0) g_center_gain = 0.0;        /* 0 = 回落到实测 ptr 增益 */']),
3161: (3161, ['点亮屏幕（摇杆大幅移动时由应用调用）。已亮时零注入']),
3166: (3166, ['真实光标位置（闭环居中用）：子进程查询，回包 CURSOR x y']),
3192: (3193, ['P <x> <y> <maxX> <maxY> : 把光标放到绝对坐标',
             '空闲隐藏会销毁鼠标设备，重建后用这条把光标放回上次的位置',
             '有界步进要 ~280ms，放子进程：主循环不被卡住']),
3309: (3309, ['每 2s 用真实 task 边界覆盖缓存：被写坏的 bounds 最多 2s 就被纠正']),
3313: (3313, ['非阻塞收尾：到期按键释放 / 排队手势启动 / 后台缓存刷新']),
3398: (3399, ['d-pad 一律上报给 App（软件在虚拟控制器层之上）',
             'App 决定这是组合键还是普通方向键，再用 H 命令回写到虚拟手柄']),
3410: (3410, ['d-pad 键同样交给 App 处理']),
3420: (3420, ['会话结束：绝不留下按住的键，也不把上一条会话的排队手势带进下一条']),
}

def chunks_of(texts):
    out = []
    for t in texts:
        t = t.strip()
        if not t:
            continue
        for part in re.split(r'[；。]', t):
            part = part.strip()
            if part:
                out.append(part)
    return out or ['']


def format_line(line, chunk):
    idx = line.find('/*')
    if idx > 0 and line[:idx].strip():
        prefix = line[:idx].rstrip() + ' '
        return prefix + '/* ' + chunk + ' */'
    indent = re.match(r'^\s*', line).group(0)
    return indent + '/* ' + chunk + ' */'


dry = '--write' not in sys.argv
FULL = {s for s, (e, t) in REPL.items()
        if e == s and '/*' in t[0] and not t[0].lstrip().startswith('/*')}
out = []
used = set()
for i, line in enumerate(lines):
    n = i + 1
    if n in FULL:
        out.append(REPL[n][1][0])
        used.add(n)
        continue
    if n in REPL:
        end_hint, texts = REPL[n]
        e = end_hint
        ch = chunks_of(texts)
        for j in range(n, e + 1):
            if j - 1 >= len(lines):
                break
            chunk = ch[j - n] if (j - n) < len(ch) else ''
            out.append(format_line(lines[j - 1], chunk))
        used.add(n)
    else:
        # 跳过属于某个已处理区域的行
        if any(s <= n <= REPL[s][0] for s in REPL if s in used and s != n):
            continue
        out.append(line)

missing = sorted(set(REPL) - used)
if missing:
    print('WARN unmatched:', missing)
if dry:
    print('dry-run: %d -> %d lines, %d regions' % (len(lines), len(out), len(REPL)))
else:
    open(PATH, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('wrote %s: %d -> %d lines, %d regions' % (PATH, len(lines), len(out), len(REPL)))
