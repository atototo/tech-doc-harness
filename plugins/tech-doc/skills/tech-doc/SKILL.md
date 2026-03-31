---
name: tech-doc
description: "코드베이스 기반 기술문서 작성 하네스. 분석→설계→작성→검증→배포 5단계. '기술문서', '아키텍처 문서', '프로세스 문서', '시스템 문서화', 'tech-doc' 요청 시 반드시 사용할 것. 코드에서 팩트를 추출하고, Mermaid/draw.io 다이어그램으로 시각화하며, Confluence에 배포한다."
---

# 기술문서 작성 하네스

코드베이스 분석 기반 기술문서를 작성하는 5단계 워크플로우.

**핵심 원칙: 코드에서 추출한 팩트만 문서화한다. 추정은 `[미확인]`으로 표시한다.**

## 참조 파일 (Progressive Disclosure)

필요한 시점에만 Read로 로드한다:

| 파일 | 로드 시점 |
|------|---------|
| `${CLAUDE_PLUGIN_ROOT}/skills/tech-doc/references/diagram-guide.md` | Phase 2-3 (다이어그램 작성 시) |
| `${CLAUDE_PLUGIN_ROOT}/skills/tech-doc/references/quality-checklist.md` | Phase 4 (검증 시) |
| `${CLAUDE_PLUGIN_ROOT}/skills/tech-doc/references/agent-guide.md` | 병렬 처리 시 |

## 실행 모드

**서브 에이전트 모드** (기본). 통신 불필요한 독립 작업이므로 Agent 도구로 직접 호출.

| 패턴 | 적용 |
|------|------|
| 팬아웃/팬인 | Phase 1 분석 (FE/BE 병렬), Phase 3 작성 (문서별 병렬) |
| 생성-검증 | Phase 3 작성 → Phase 4 검증 |

## Phase 1: 분석 (Analyze)

코드에서 팩트를 추출한다.

### 실행
`analyzer` 에이전트로 분석한다. FE/BE 병렬 분석 가능.

```
# 단일 분석
Agent(subagent_type="tech-doc:analyzer", prompt="... {type} 분석 ...")

# FE/BE 병렬 분석 (단일 메시지에서 동시 호출)
Agent(subagent_type="tech-doc:analyzer", name="fe-analysis", run_in_background=true,
      prompt="FE({fe_path})에서 {type} 분석")
Agent(subagent_type="tech-doc:analyzer", name="be-analysis", run_in_background=true,
      prompt="BE({be_path})에서 {type} 분석")
```

문서 유형에 따라 분석 항목 결정 (analyzer가 체크리스트를 내장):

| 문서 유형 | 분석 항목 |
|----------|---------|
| architecture | 환경변수, DB설정, API라우팅, 패키지구조 |
| process-flow | Controller→Service 호출체인, 상태전이, 배치작업 |
| integration | 외부API 호출 클래스, 인증방식, 에러핸들링 |
| domain-spec | 엔드포인트 목록, Entity구조, FE페이지구조 |

### 산출물
- 팩트 목록 (소스 파일 경로 포함)
- 불확실 항목에 `[확인필요]` 태그

## Phase 2: 구조 설계 (Structure)

### 다이어그램 도구 선택

| 유형 | 도구 |
|------|------|
| 아키텍처 구성도 (영역/존) | draw.io (.drawio 첨부) |
| 시퀀스/프로세스 플로우 | Mermaid (markdown 매크로) |
| 상태 전이 | Mermaid (stateDiagram-v2) |
| 플로우차트 | Mermaid (graph) |

다이어그램 상세 규칙은 `references/diagram-guide.md` 참조.

### 사용자 확인
목차 + 다이어그램 목록을 사용자에게 제시. 피드백 반영 후 진행.

## Phase 3: 작성 (Write)

`writer` 에이전트로 작성한다. 독립 문서 여러 개는 병렬 실행.

```
# 단일 문서
Agent(subagent_type="tech-doc:writer", mode="bypassPermissions",
      prompt="... Phase 1 팩트 + Phase 2 구조 전달 ...")

# 병렬 작성 (독립 문서)
Agent(subagent_type="tech-doc:writer", name="gift-doc", run_in_background=true, mode="bypassPermissions",
      prompt="Gift 프로세스 플로우 작성. 팩트: {...} 구조: {...}")
Agent(subagent_type="tech-doc:writer", name="kink-doc", run_in_background=true, mode="bypassPermissions",
      prompt="Kink 프로세스 플로우 작성. 팩트: {...} 구조: {...}")
```

### 원칙
1. **다이어그램 우선** — 글보다 다이어그램으로 먼저 설명
2. **최소 텍스트** — 다이어그램이 설명 못하는 부분만 보충
3. **표 활용** — 나열형 정보는 표로
4. **이모지 금지** — 색상과 shape으로 구분. 문서가 가벼워 보임

### Confluence 배포 (번들 스크립트 사용)

스크립트를 사용하여 토큰을 절약한다. 경로: `${CLAUDE_PLUGIN_ROOT}/scripts/`

```bash
# Mermaid 래핑 (config 자동 적용)
echo "graph LR\n  A-->B" | ${CLAUDE_PLUGIN_ROOT}/scripts/mermaid-wrap.sh > /tmp/diagram.html

# 페이지 생성
${CLAUDE_PLUGIN_ROOT}/scripts/wiki-publish.sh <parent_id> "제목" /tmp/body.html

# 페이지 수정
${CLAUDE_PLUGIN_ROOT}/scripts/wiki-publish.sh <parent_id> "제목" /tmp/body.html <page_id>

# 첨부파일 업로드 (draw.io, 스크린샷 등)
${CLAUDE_PLUGIN_ROOT}/scripts/wiki-upload.sh <page_id> /tmp/diagram.drawio

# API 경로 검증 (Phase 4)
${CLAUDE_PLUGIN_ROOT}/scripts/verify-doc.sh /tmp/checks.txt /path/to/fe /path/to/be
```

## Phase 4: 검증 (Verify)

**건너뛰지 않는다.**

`reviewer` 에이전트 + `verify-doc.sh` 스크립트 조합으로 검증.

```
# 자동 검증 (스크립트) — API 경로 존재 확인
${CLAUDE_PLUGIN_ROOT}/scripts/verify-doc.sh /tmp/checks.txt <fe_path> <be_path>

# 심층 검증 (에이전트) — 호출 관계, 프로세스 정확성
Agent(subagent_type="tech-doc:reviewer",
      prompt="다음 문서를 검증: {문서 내용 요약}. FE: {fe_path}, BE: {be_path}")
```

### 자동 검증 (스크립트)
문서에서 언급한 API 경로/서비스명을 추출하여 `verify-doc.sh`로 자동 검증:
```bash
cat > /tmp/checks.txt << EOF
/api/v1/gift/crawling
/api/v1/kink/models/upload
JobStatusEnum
useCustomFetch
EOF

${CLAUDE_PLUGIN_ROOT}/scripts/verify-doc.sh /tmp/checks.txt /path/to/fe /path/to/be
```

### 수동 검증 (체크리스트)
`references/quality-checklist.md`를 Read로 로드 후 자동 검증에서 커버하지 못하는 항목 확인:
- 다이어그램 호출 관계가 실제 코드와 일치하는지
- 자동 파이프라인으로 기술한 것이 실제로 자동인지
- 각 항목에 PASS/WARN/FAIL 판정

FAIL 있으면 수정 후 재검증.

## Phase 5: 배포 (Publish)

```bash
# 1. HTML 본문 파일 생성 (Phase 3 산출물)
# 2. 페이지 생성
${CLAUDE_PLUGIN_ROOT}/scripts/wiki-publish.sh <parent_id> "제목" /tmp/body.html
# 3. 첨부파일 업로드 (draw.io 등)
${CLAUDE_PLUGIN_ROOT}/scripts/wiki-upload.sh <page_id> /tmp/diagram.drawio
```

## 병렬 처리

독립 문서 여러 개 동시 작성 시:

```
# Phase 1: analyzer 병렬 (FE/BE)
Agent(subagent_type="tech-doc:analyzer", name="fe", run_in_background=true, prompt="FE 분석")
Agent(subagent_type="tech-doc:analyzer", name="be", run_in_background=true, prompt="BE 분석")

# Phase 3: writer 병렬 (문서별)
Agent(subagent_type="tech-doc:writer", name="doc-1", run_in_background=true, mode="bypassPermissions", ...)
Agent(subagent_type="tech-doc:writer", name="doc-2", run_in_background=true, mode="bypassPermissions", ...)

# Phase 4: reviewer (작성 완료 후)
Agent(subagent_type="tech-doc:reviewer", prompt="문서 1,2 검증")
```

## 비용 최적화

| 방법 | 절감 |
|------|------|
| analyzer = sonnet 모델 | 분석은 sonnet으로 충분, opus 대비 ~3x 저렴 |
| 번들 스크립트 (wiki-publish 등) | 반복 boilerplate 토큰 절약 |
| Progressive Disclosure | references/ 필요 시만 Read |
| 팩트 재사용 | Phase 1 결과를 Phase 3 에이전트에 직접 전달 (재분석 방지) |
| verify-doc.sh | 검증의 50%를 스크립트로 자동화 (에이전트 토큰 절약) |

## 안티패턴

- Controller 클래스명 나열 (→ 기능 중심)
- Vault 경로 등 구현 디테일 (→ 아키텍처 수준 추상화)
- 다이어그램 없이 텍스트만 (→ 다이어그램 우선)
- 코드 미확인 추정 (→ Phase 1 팩트만)
- 이모지 남용 (→ 색상/shape으로 구분)
- PlantUML 사용 (→ Mermaid/draw.io로 대체)
