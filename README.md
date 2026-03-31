# tech-doc-harness

코드베이스 기반 기술문서 작성 하네스 (Claude Code Plugin)

## 개요

코드에서 팩트를 추출하여 기술문서를 작성하는 5단계 워크플로우입니다.
Mermaid/draw.io 다이어그램을 지원하며 Confluence에 배포합니다.

```
Phase 1: 분석    → 코드에서 팩트 추출 (Explore 에이전트)
Phase 2: 설계    → 문서 구조 + 다이어그램 설계
Phase 3: 작성    → Mermaid/draw.io 다이어그램 + Confluence Storage Format
Phase 4: 검증    → 코드 대조 검증 (anti-hallucination)
Phase 5: 배포    → Confluence API 배포
```

## 설치

```bash
claude plugin add github.com/atototo/tech-doc-harness
```

## 사용법

```
/tech-doc <문서유형> <대상>
```

문서 유형:
- `architecture` - 시스템 아키텍처
- `process-flow` - 프로세스 플로우
- `integration` - 외부 연동 명세
- `domain-spec` - 도메인 기능 명세

## 구조

```
├── scripts/                    # 토큰 절약 번들 스크립트
│   ├── wiki-publish.sh         # Confluence 페이지 생성/수정
│   ├── wiki-upload.sh          # 첨부파일 업로드
│   ├── mermaid-wrap.sh         # Mermaid → Confluence 매크로 래핑
│   └── verify-doc.sh           # 문서-코드 불일치 자동 검증
├── skills/tech-doc/
│   ├── SKILL.md                # 메인 스킬 (5단계 워크플로우)
│   └── references/             # Progressive Disclosure
│       ├── diagram-guide.md    # Mermaid/draw.io 작성 규칙
│       ├── quality-checklist.md # 검증 체크리스트
│       └── agent-guide.md      # 서브에이전트 구성 패턴
└── plugin.json
```

## 다이어그램 전략

| 유형 | 도구 | 이유 |
|------|------|------|
| 아키텍처 구성도 | draw.io | 영역/존 구분, 레이아웃 자유도 |
| 시퀀스/프로세스 | Mermaid (handDrawn) | autonumber, rect 영역 |
| 상태 전이 | Mermaid | stateDiagram-v2 |
| 플로우차트 | Mermaid | classDef 색상 분류 |

## 환경변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `CONFLUENCE_TOKEN` | Confluence API 토큰 | (필수) |
| `WIKI_HOST` | Confluence 호스트 | wiki.daumkakao.com |
| `WIKI_SPACE_KEY` | Space Key | yomojomo |

## License

MIT
