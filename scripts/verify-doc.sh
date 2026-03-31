#!/bin/bash
# verify-doc.sh - 문서에 언급된 API 경로/서비스가 코드에 존재하는지 자동 검증
# Usage: verify-doc.sh <check_file> <code_dir1> [code_dir2 ...]
#
# check_file 형식 (한 줄에 하나):
#   /api/v1/gift/crawling
#   /api/v1/kink/models/upload
#   JobStatusEnum
#   useCustomFetch
#
# 예시: verify-doc.sh /tmp/checks.txt /path/to/fe /path/to/be

set -euo pipefail

CHECK_FILE="$1"
shift
CODE_DIRS=("$@")

PASS=0
WARN=0
FAIL=0

echo "=== 문서 검증 시작 ==="
echo "검증 항목: $(wc -l < "$CHECK_FILE" | tr -d ' ')개"
echo "코드 디렉토리: ${CODE_DIRS[*]}"
echo ""

while IFS= read -r term || [ -n "$term" ]; do
  # 빈 줄/주석 무시
  [[ -z "$term" || "$term" == \#* ]] && continue

  FOUND=false
  FOUND_IN=""

  for DIR in "${CODE_DIRS[@]}"; do
    # rg가 있으면 rg, 없으면 grep 사용
    if command -v rg &>/dev/null; then
      MATCHES=$(rg -l --no-heading "$term" "$DIR" --glob '!node_modules' --glob '!.git' --glob '!build' --glob '!bin' 2>/dev/null | head -3)
    else
      MATCHES=$(grep -rl "$term" "$DIR" --include='*.java' --include='*.js' --include='*.ts' --include='*.vue' --include='*.yaml' --include='*.yml' --include='*.json' 2>/dev/null | head -3)
    fi

    if [ -n "$MATCHES" ]; then
      FOUND=true
      FOUND_IN=$(echo "$MATCHES" | head -1)
      break
    fi
  done

  if [ "$FOUND" = true ]; then
    echo "PASS | $term | $FOUND_IN"
    ((PASS++))
  else
    echo "FAIL | $term | NOT FOUND"
    ((FAIL++))
  fi
done < "$CHECK_FILE"

echo ""
echo "=== 검증 결과 ==="
echo "PASS: $PASS | FAIL: $FAIL"
echo "통과율: $(echo "scale=0; $PASS * 100 / ($PASS + $FAIL)" | bc 2>/dev/null || echo "?")%"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
