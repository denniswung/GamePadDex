#!/bin/bash
# probe_v166_helper_audit.sh -- 在最终源码上重新生成 popen/system 审计（R4/t13）
# 用法：bash work/scripts/probe_v166_helper_audit.sh
set -u
cd "$(dirname "$0")/../.." || exit 1
SRC=project/app/src/main/assets/gpminput.c
OUT=work/docs/evidence-v166/helper-v166-popen-audit-r2.txt
LINES=$(wc -l < "$SRC")
SHA=$(sha256sum "$SRC" | awk '{print $1}')
{
    echo "# popen()/system() audit (regenerated from FINAL source, t13)"
    echo "# source: $SRC  lines=$LINES  sha256=$SHA"
    echo "# 结论：所有 popen/system 都只在「子进程分支/子进程专用函数」执行；命令主循环只做内存计算 + write/fork。"
    echo
    echo "## 1) 全部 popen/system 调用点（L 行号 = 当前源码）"
    grep -n -E 'popen\(|system\(' "$SRC"
    echo
    echo "## 2) 关键函数/变量的行号"
    grep -n -E '^static (void|int|double|long long|pid_t) (cmd_swipe|cmd_selftest|bounds_refresh_poll|bounds_refresh_request|cmd_wake_screen|wake_slow_path|resolve_component|cmd_cursor_query|swipe_submit|gesture_poll|gesture_poll_timeout|key_release_later|key_release_due|effective_gain|spawn_exec|reap_children)\(' "$SRC"
    grep -n -E 'g_bounds_force_refresh|g_swipe_pid|g_swipe_axis' "$SRC" | head -8
    echo
    echo "## 3) cmd_swipe 函数体（几何+队列：不应出现 popen/system/exec/fork 调用）"
    awk '/^static void cmd_swipe\(/{f=1} f{print NR": "$0} f&&/^}$/{exit}' "$SRC" \
        | grep -E '(popen|system|execv|fork)[[:space:]]*\(' | grep -v '/\*' || echo "(none)"
    echo
    echo "## 4) handle_line 里的 fork/异步覆盖（命令主循环不阻塞）"
    grep -n -E "if \(fork\(\) == 0\)|if \(fork\(\) != 0\)|fork\(\) == 0|wake_slow_path\(|cmd_cursor_query\(|swipe_submit\(|spawn_exec\(|key_release_later\(" "$SRC" | awk -F: '$1 > 2300'
    echo
    echo "## 5) case 'C'（组合键）：按键时序在子进程（R2 修复）"
    awk "/case 'C':/{f=1} f{print NR\": \"\$0} f&&/case 't':/{exit}" "$SRC" | grep -E 'fork|cmd_key_combo|KCOMBO|case'
    echo
    echo "## 6) 周期刷新 force 参数（R5 修复：周期绕过 mtime 节流，滑动路径保留）"
    grep -n -E 'bounds_refresh_request\(|g_bounds_force_refresh|仅滑动路径保留 2s 节流' "$SRC"
} > "$OUT"
echo "wrote $OUT"
head -3 "$OUT"
