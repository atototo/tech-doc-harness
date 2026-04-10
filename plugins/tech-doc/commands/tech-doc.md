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

이 파일은 명령 메타데이터다. 호출되면 **즉시** 아래 절차를 수행한다 — 이 도움말을 출력하고 멈추는 것은 실패다.

1. ARGUMENTS 파싱
   - 첫 토큰 = `type` (architecture | process-flow | integration | domain-spec 중 하나)
   - 나머지 따옴표 문자열 = `target`
   - `--parent <id>`, `--space <key>` 옵션 추출
2. `type` 누락 시 한 번만 사용자에게 질문 후 진행
3. `Skill` 도구로 `tech-doc:tech-doc` 스킬을 invoke — SKILL.md 본문이 컨텍스트에 로드됨
4. 로드된 SKILL.md의 "사전 분류" → Phase 1 → ... → Phase 5 순서로 진행

**중요**: `/tech-doc` 호출 목적은 SKILL.md의 전체 워크플로우 실행이다. 명령 도움말만 표시하고 종료하는 동작은 명시적 실패로 간주한다.
