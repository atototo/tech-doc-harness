---
name: tech-doc
description: "기술문서 작성. /tech-doc <type> <target> 형태로 호출. type: architecture, process-flow, integration, domain-spec"
---

# /tech-doc 커맨드

기술문서 작성 하네스를 실행합니다.

## 사용법

```
/tech-doc <type> <target> [--parent <page_id>] [--space <space_key>]
```

### 인자

| 인자 | 설명 | 예시 |
|------|------|------|
| `type` | 문서 유형 | architecture, process-flow, integration, domain-spec |
| `target` | 문서화 대상 | "Gift 도메인", "인증 흐름", "전체 시스템" |
| `--parent` | Confluence 부모 페이지 ID | 2081209993 |
| `--space` | Confluence Space Key (기본: yomojomo) | yomojomo |

### 예시

```bash
/tech-doc process-flow "Gift 도메인"
/tech-doc architecture "SCORPIO 전체" --parent 2081209993
/tech-doc integration "외부 서비스 연동"
```

## 실행

`tech-doc` 스킬을 로드하고 Phase 1부터 순서대로 진행합니다.
