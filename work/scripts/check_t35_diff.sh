#!/bin/bash
# t35 校验：diff 只含注释行变化（HEAD 与 pre-task 备份两种基线）
cd "$(dirname "$0")/../.." || exit 1
SRC=project/app/src/main/assets/gpminput.c
echo "== vs pre-task backup =="
diff -u work/tmp_gpminput_pre_t35.c "$SRC" | grep -E '^[+-][^+-]' | grep -vE '^[+-][[:space:]]*(/\*|\*|//)' | head -20
echo "non_comment_lines=$(diff -u work/tmp_gpminput_pre_t35.c "$SRC" | grep -E '^[+-][^+-]' | grep -vE '^[+-][[:space:]]*(/\*|\*|//)' | wc -l)"
echo "== vs git HEAD (acceptance literal command) =="
git diff -U0 -- "$SRC" | grep -E '^[+-][^+-]' | grep -vE '^[+-]\s*(/\*|\*|//)' | wc -l
echo "== changed comment-line ranges vs backup =="
diff -u work/tmp_gpminput_pre_t35.c "$SRC" | grep -E '^@@' | head -40
