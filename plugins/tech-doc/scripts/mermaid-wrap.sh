#!/bin/bash
# mermaid-wrap.sh - Mermaid 코드를 Confluence markdown 매크로로 래핑
# Usage: mermaid-wrap.sh < mermaid_code.txt > wrapped.html
#        mermaid-wrap.sh mermaid_code.txt > wrapped.html
#
# 기본 config(handDrawn + base theme)를 자동 적용한다.
# --no-config 옵션으로 config 없이 래핑 가능.

NO_CONFIG=false
INPUT_FILE=""

for arg in "$@"; do
  case $arg in
    --no-config) NO_CONFIG=true ;;
    *) INPUT_FILE="$arg" ;;
  esac
done

if [ -n "$INPUT_FILE" ]; then
  MERMAID_CODE=$(cat "$INPUT_FILE")
else
  MERMAID_CODE=$(cat)
fi

if [ "$NO_CONFIG" = true ]; then
  CONFIG=""
else
  CONFIG="---
config:
  look: handDrawn
  theme: base
  themeVariables:
    primaryColor: '#dbeafe'
    primaryTextColor: '#1e3a5f'
    lineColor: '#6b7280'
    fontFamily: 'Helvetica, Arial, sans-serif'
---
"
fi

cat << XMLEOF
<ac:structured-macro ac:name="markdown">
<ac:plain-text-body><![CDATA[
\`\`\`mermaid
${CONFIG}${MERMAID_CODE}
\`\`\`
]]></ac:plain-text-body>
</ac:structured-macro>
XMLEOF
