---
name: state-trail-code-review
description: StateTrail 변경을 OpenSpec, ADR, architecture, quality harness, LogQL, fallback 관점으로 리뷰하도록 안내합니다.
---

StateTrail 변경을 리뷰할 때 repo-local `state-trail-code-reviewer` agent 또는 generic code review workflow와 함께 사용합니다. 이 스킬은 StateTrail 전용 확인 순서를 제공하며, 장기 정책 원문은 source of truth 문서를 참조합니다.

**Source of Truth**

- 제품/아키텍처 경계: `@ARCHITECTURE.md`
- 현재 동작 계약: `openspec/specs/`
- 품질 하네스 계약: `openspec/specs/quality-harness/spec.md`
- 장기 결정 근거: `docs/adr/`
- 활성 OpenSpec change: `openspec/changes/<change>/`

**리뷰 원칙**

- 결함, 회귀, 누락된 검증, 계약 위반을 먼저 찾습니다.
- 장기 정책 원문을 리뷰 코멘트에 다시 정의하지 말고, 관련 source-of-truth 경로를 인용합니다.
- 구현 스타일보다 StateTrail의 관찰 가능한 동작, evidence, 실패 시 진단 가능성을 우선합니다.
- 일반적인 StateTrail 리뷰는 `.codex/agents/state-trail-code-reviewer.toml`을 사용해 경량 모델로 실행하고, 보안/아키텍처/high-risk 변경은 global `code-reviewer` 또는 `architect`로 올립니다.

**절차**

1. **적용 가능한 계약을 확인합니다**
   - 변경이 관찰 가능한 제품 동작이나 외부 계약을 바꾸면 관련 OpenSpec change 또는 `openspec/specs/`와 일치하는지 확인합니다.
   - 모듈 경계, 의존 방향, 제품 책임이 바뀌면 `@ARCHITECTURE.md`와 충돌하지 않는지 확인합니다.
   - 이후 작업을 제약할 결정이 새로 생겼다면 ADR 필요 여부를 확인합니다.

2. **테스트 충분성을 검토합니다**
   - API 동작 변경에는 happy-case API integration test가 있는지 확인합니다.
   - 의미 있는 validation, state, authorization, ordering, error edge condition이 있으면 edge-case 테스트 2~3개 또는 더 적은 이유가 기록됐는지 확인합니다.
   - 테스트가 private helper나 임시 구현 순서가 아니라 observable behavior를 검증하는지 봅니다.

3. **harness evidence를 확인합니다**
   - behavior, tests, hooks, CI, logs에 영향을 주는 변경이면 관련 harness command가 실행됐는지 확인합니다.
   - 실행하지 못한 검증은 validation gap으로 명시되어야 합니다.
   - script가 강제할 수 있는 기계적 조건과 reviewer가 판단해야 하는 충분성 조건을 혼동하지 않습니다.

4. **LogQL 검증 경로를 확인합니다**
   - LogQL query definition 또는 로그 evidence를 건드리면 fast static validation 대상 metadata가 충분한지 확인합니다.
   - live-required query 또는 대표 로그 fixture가 있으면 strict live query가 조용히 skip되지 않고 성공/실패를 드러내는지 확인합니다.
   - live check가 설정되지 않은 strict 모드는 이를 명시적으로 보고하는지 확인합니다.

5. **fallback과 compatibility를 검토합니다**
   - fallback, compatibility, best-effort 동작은 실패 evidence를 보존해야 합니다.
   - fallback이 root cause를 숨기거나, CI/harness/log evidence 실패를 성공처럼 보이게 만들면 차단 이슈로 봅니다.
   - fallback 경로에도 사용자가 진단할 수 있는 메시지, 로그, 테스트 evidence가 있는지 확인합니다.

6. **리뷰 결과를 우선순위로 정리합니다**
   - Findings를 먼저 쓰고, 파일/라인과 실패 조건을 구체적으로 적습니다.
   - 그 다음 open questions, 검증 gap, 변경 요약을 짧게 둡니다.
   - 문제가 없으면 그렇게 말하고 남은 risk 또는 실행하지 못한 검증만 남깁니다.

**체크리스트**

- [ ] 관련 OpenSpec/spec, ADR, architecture source of truth를 확인했습니다.
- [ ] API happy-case와 edge-case coverage가 변경 위험에 맞습니다.
- [ ] 테스트가 behavior-focused이며 구현 세부에 과도하게 결합하지 않습니다.
- [ ] 관련 harness command evidence 또는 validation gap이 있습니다.
- [ ] LogQL static/live mode 기대가 변경과 일치합니다.
- [ ] fallback이 failure evidence와 root cause를 숨기지 않습니다.

**출력 형식**

```text
Findings:
- <severity> <파일:라인> <문제와 실패 조건>

Open questions:
- <없음 또는 질문>

Verification reviewed:
- <명령/evidence 또는 gap>

Summary:
- <짧은 변경/리뷰 요약>
```

**전용 agent 라우팅 기준**

기본 StateTrail 리뷰는 전용 `.codex/agents/state-trail-code-reviewer.toml`을 사용합니다. 이 agent는 `gpt-5.4` 기반의 Sonnet급 리뷰 표면이며, OpenSpec/ADR/architecture/harness/LogQL/fallback evidence처럼 저장소 전용 체크를 빠르게 수행하기 위한 용도입니다.

다음 경우에는 더 무거운 global `code-reviewer`, `architect`, `verifier`를 함께 사용하거나 대체합니다.

- 보안, 권한, 외부 입력, credential, 데이터 손실 위험이 있는 변경입니다.
- 아키텍처 경계, 모듈 의존 방향, 장기 운영 결정을 바꿉니다.
- 여러 모듈에 걸친 큰 diff라 경량 리뷰만으로 blast radius를 판단하기 어렵습니다.
- 경량 리뷰가 `REQUEST CHANGES`를 냈고, 수정 방향이 설계 판단을 요구합니다.
