#!/bin/bash
# t35 证据汇总
cd "$(dirname "$0")/../.." || exit 1
OUT=work/docs/evidence-v168/helper-v168-mojibake-cleanup.txt
SRC=project/app/src/main/assets/gpminput.c
{
  echo "== t35 mojibake comment cleanup $(date) =="
  echo "-- source: $SRC"
  wc -l "$SRC"
  sha256sum "$SRC"
  echo "-- UTF-8/BOM/mojibake:"
  python3 work/scripts/check_t35_utf8.py
  echo "-- code prefix check (diff vs pre-task backup):"
  python3 work/scripts/check_t35_codeprefix.py
  echo "-- non-comment diff lines (vs pre-task backup, trailing-comment lines only):"
  diff -u work/tmp_gpminput_pre_t35.c "$SRC" | grep -E '^[+-][^+-]' | grep -vE '^[+-][[:space:]]*(/\*|\*|//)' | wc -l
  echo "-- changed hunks:"
  diff -u work/tmp_gpminput_pre_t35.c "$SRC" | grep -E '^@@'
} > "$OUT"
echo "wrote $OUT"
