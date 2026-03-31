#!/bin/bash
# wiki-upload.sh - Confluence 페이지에 첨부파일 업로드
# Usage: wiki-upload.sh <page_id> <file_path> [file_path2 ...]
#
# 예시: wiki-upload.sh 2081219725 /tmp/diagram.drawio /tmp/screenshot.png

set -euo pipefail
source ~/.zshrc 2>/dev/null || true

PAGE_ID="$1"
shift

if [ -z "$CONFLUENCE_TOKEN" ]; then
  echo "ERROR: CONFLUENCE_TOKEN not set" >&2
  exit 1
fi

for FILE_PATH in "$@"; do
  FILENAME=$(basename "$FILE_PATH")
  RESULT=$(curl -s -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
    -H "X-Atlassian-Token: nocheck" \
    -X POST "https://${WIKI_HOST:?WIKI_HOST not set}/rest/api/content/$PAGE_ID/child/attachment" \
    -F "file=@$FILE_PATH")

  echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
fname='$FILENAME'
if 'results' in d: print(f'OK|{fname}|{d[\"results\"][0][\"id\"]}')
elif 'title' in d: print(f'OK|{fname}|{d[\"id\"]}')
else: print(f'ERR|{fname}|{str(d)[:100]}')
" 2>/dev/null || echo "ERR|$FILENAME|parse_failed"
done
