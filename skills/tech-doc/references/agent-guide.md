# 에이전트 구성 가이드

tech-doc 하네스에서 서브 에이전트를 활용하는 패턴.

## 실행 모드: 서브 에이전트

tech-doc은 통신 불필요한 독립 작업이므로 서브 에이전트 모드를 사용한다.
에이전트 팀(TeamCreate)은 사용하지 않는다.

## 패턴 1: 분석 팬아웃 (Phase 1)

FE/BE 코드베이스를 병렬로 분석한다.

```
Agent(subagent_type="Explore", name="fe-analyzer")  ← FE 코드 분석
Agent(subagent_type="Explore", name="be-analyzer")  ← BE 코드 분석
→ 메인에서 결과 통합
```

- `Explore` 타입 사용 (읽기 전용, 코드 수정 방지)
- `run_in_background: true`로 병렬 실행
- 분석 결과는 메인 컨텍스트로 반환

## 패턴 2: 문서 작성 팬아웃 (Phase 3)

독립된 문서 여러 개를 동시 작성한다.

```
Agent(name="auth-doc", mode="bypassPermissions")   ← 인증 문서
Agent(name="gift-doc", mode="bypassPermissions")   ← Gift 문서
Agent(name="kink-doc", mode="bypassPermissions")   ← Kink 문서
→ 메인에서 결과 수집
```

- `mode: "bypassPermissions"` — Bash(curl) 실행 필요
- 각 에이전트에 전달할 정보:
  1. 검증된 분석 결과 (Phase 1 산출물)
  2. 다이어그램 규칙 (diagram-guide.md 핵심)
  3. Confluence API 인증 정보 ($CONFLUENCE_TOKEN)
  4. 부모 페이지 ID, Space Key

## 패턴 3: 생성-검증 (Phase 3→4)

작성 후 별도 에이전트로 검증한다.

```
Phase 3: Agent(name="writer")     ← 문서 작성
Phase 4: Agent(subagent_type="ai-party:reviewer")  ← 코드 대조 검증
→ FAIL 항목은 메인에서 수정
```

- Reviewer는 `ai-party:reviewer` 타입 사용
- 검증 프롬프트에 quality-checklist.md 항목 포함
- PASS/WARN/FAIL 결과 반환

## 에이전트 프롬프트 템플릿

### 분석 에이전트
```
{프로젝트 경로}에서 {도메인}의 {분석 항목}을 분석해줘.
코드를 수정하지 말고 분석만. 구체적인 파일명과 라인번호 포함.
```

### 작성 에이전트
```
Confluence 위키 페이지를 생성해줘. 코드 수정 없이 위키만 생성.
부모 페이지 ID: {id}, Space: {key}
인증: source ~/.zshrc 후 $CONFLUENCE_TOKEN

## 검증된 분석 결과:
{Phase 1 산출물}

## 다이어그램 규칙:
- Mermaid: markdown 매크로, handDrawn + base theme, classDef 색상, 이모지 금지
- draw.io: .drawio 첨부 + drawio 매크로 (diagramName에 확장자 포함)

## 문서 구조:
{Phase 2 목차}

Python으로 JSON 생성 후 curl POST. 완료 후 Page ID와 URL 출력.
```

### 검증 에이전트
```
다음 위키 문서의 내용이 실제 코드와 일치하는지 검증해줘.
FE: {fe_path}, BE: {be_path}

## 검증 항목:
{quality-checklist.md 기반 구체적 검증 항목}

각 항목별로 PASS/WARN/FAIL 결과를 보고해줘.
코드를 수정하지 말고 검증만.
```

## 비용 최적화

| 방법 | 효과 |
|------|------|
| Explore 타입 사용 (분석) | 읽기 전용, 불필요한 도구 호출 방지 |
| Progressive Disclosure | references/ 필요 시만 로드 |
| 분석 결과 재사용 | Phase 1 산출물을 Phase 3 에이전트에 직접 전달 (재분석 방지) |
| 검증 항목 구체화 | 검증 에이전트에 정확한 체크 항목 전달 (탐색 시간 절약) |
