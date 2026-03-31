#!/bin/bash
# wiki-publish.sh - Confluence 페이지 생성/수정
# Usage: wiki-publish.sh <parent_id> <title> <body_html_file> [page_id_for_update]
#
# 생성: wiki-publish.sh 2081209993 "페이지 제목" /tmp/body.html
# 수정: wiki-publish.sh 2081209993 "페이지 제목" /tmp/body.html 2081219725

set -euo pipefail
source ~/.zshrc 2>/dev/null || true

PARENT_ID="$1"
TITLE="$2"
BODY_FILE="$3"
PAGE_ID="${4:-}"
SPACE_KEY="${WIKI_SPACE_KEY:-yomojomo}"

if [ -z "$CONFLUENCE_TOKEN" ]; then
  echo "ERROR: CONFLUENCE_TOKEN not set" >&2
  exit 1
fi

BODY_HTML=$(cat "$BODY_FILE")

if [ -n "$PAGE_ID" ]; then
  # 수정 모드: 현재 버전 조회
  CUR_VER=$(curl -s -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
    "https://${WIKI_HOST:-wiki.daumkakao.com}/rest/api/content/$PAGE_ID?expand=version" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['version']['number'])")
  NEW_VER=$((CUR_VER + 1))

  python3 -c "
import json, sys
payload = {
    'type': 'page',
    'title': sys.argv[1],
    'space': {'key': sys.argv[2]},
    'version': {'number': int(sys.argv[3])},
    'ancestors': [{'id': int(sys.argv[4])}],
    'body': {'storage': {'value': sys.stdin.read(), 'representation': 'storage'}}
}
json.dump(payload, open('/tmp/_wiki_payload.json','w'), ensure_ascii=False)
" "$TITLE" "$SPACE_KEY" "$NEW_VER" "$PARENT_ID" <<< "$BODY_HTML"

  RESULT=$(curl -s -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
    -H "Content-Type: application/json" \
    -X PUT "https://${WIKI_HOST:-wiki.daumkakao.com}/rest/api/content/$PAGE_ID" \
    -d @/tmp/_wiki_payload.json)
else
  # 생성 모드
  python3 -c "
import json, sys
payload = {
    'type': 'page',
    'title': sys.argv[1],
    'space': {'key': sys.argv[2]},
    'ancestors': [{'id': int(sys.argv[3])}],
    'body': {'storage': {'value': sys.stdin.read(), 'representation': 'storage'}}
}
json.dump(payload, open('/tmp/_wiki_payload.json','w'), ensure_ascii=False)
" "$TITLE" "$SPACE_KEY" "$PARENT_ID" <<< "$BODY_HTML"

  RESULT=$(curl -s -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "https://${WIKI_HOST:-wiki.daumkakao.com}/rest/api/content" \
    -d @/tmp/_wiki_payload.json)
fi

# 결과 파싱
echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'id' in d:
    print(f'OK|{d[\"id\"]}|{d[\"title\"]}|v{d[\"version\"][\"number\"]}')
else:
    print(f'ERR|{d.get(\"message\",\"unknown\")[:200]}')
    sys.exit(1)
"
rm -f /tmp/_wiki_payload.json
