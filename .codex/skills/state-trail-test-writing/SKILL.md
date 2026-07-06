---
name: state-trail-test-writing
description: StateTrail 변경의 API 통합 테스트, edge-case 테스트, behavior-focused coverage, 검증 evidence 작성을 안내합니다.
---

StateTrail 변경에 맞는 테스트를 작성하거나 보완할 때 사용합니다. 이 스킬은 테스트 충분성을 판단하는 실행 표면이며, 장기 정책의 원문은 아래 source of truth를 확인하세요.

**Source of Truth**

- 제품/아키텍처 경계: `@ARCHITECTURE.md`
- 현재 동작 계약: `openspec/specs/`
- 진행 중인 품질 하네스 변경: `openspec/changes/d20260706-add-state-trail-harness/`
- 장기 결정 근거: `docs/adr/`

**입력**

- 변경하려는 기능, 버그 수정, 리팩터링 범위
- 관련 OpenSpec change 또는 spec 경로가 있으면 함께 확인합니다
- API, 로그, hook, CI, 테스트 하네스 중 영향을 받는 표면

**절차**

1. **변경 표면을 분류합니다**
   - 관찰 가능한 API 동작이 추가되거나 바뀌는지 확인합니다.
   - API 표면이 없으면 억지 API 테스트를 만들지 말고, 영향을 받는 contract를 실행하는 behavior-focused coverage를 선택합니다.
   - OpenSpec, ADR, architecture 문서와 충돌하는 기대사항이 있으면 구현보다 먼저 충돌을 보고합니다.

2. **API happy-case 통합 테스트를 둡니다**
   - API 동작이 추가되거나 바뀌면 HTTP-style client 또는 프로젝트가 승인한 equivalent로 실제 API 경로를 실행하는 happy-case 통합 테스트를 최소 하나 작성합니다.
   - 테스트는 구현 내부 함수 호출보다 요청, 응답, 상태 전이, 외부에 보이는 결과를 검증합니다.
   - client 선택은 대상 모듈과 기존 패턴을 따릅니다. 예시는 MockMvc, RestClient, WebTestClient 또는 프로젝트가 승인한 다른 client입니다.

3. **edge-case를 위험 기반으로 고릅니다**
   - validation, state, authorization, ordering, error condition이 있으면 의미 있는 edge-case 테스트를 보통 2~3개 추가합니다.
   - edge-case가 2개보다 적어도 충분한 경우에는 PR 설명, change note, review note 중 하나에 이유를 남깁니다.
   - edge-case 개수 자체보다 실패했을 때 사용자-visible contract가 깨지는 조건을 우선합니다.

4. **behavior-focused coverage를 유지합니다**
   - 테스트 이름과 assertion은 비즈니스 동작, API 계약, 상태 전이, 에러 응답처럼 관찰 가능한 결과를 중심으로 씁니다.
   - 저장소 내부 클래스 배치, private helper, 임시 구현 순서처럼 쉽게 바뀌는 세부사항에 결합하지 않습니다.
   - 순수 내부 리팩터링이면 변경된 내부 단위가 보장해야 하는 contract를 작은 단위 테스트로 고정합니다.

5. **검증 evidence를 남깁니다**
   - 실행한 테스트 명령과 결과를 기록합니다.
   - 관련 harness가 있으면 해당 명령도 실행하거나 실행하지 못한 이유를 명시합니다.
   - 검증 gap이 남으면 어떤 위험이 남는지와 후속 검증 조건을 적습니다.

**체크리스트**

- [ ] 관련 OpenSpec/spec, ADR, architecture guidance를 확인했습니다.
- [ ] API 변경에는 happy-case API integration test가 있습니다.
- [ ] 의미 있는 edge condition을 2~3개 테스트했거나, 더 적은 이유를 기록했습니다.
- [ ] 테스트가 구현 세부가 아니라 관찰 가능한 behavior를 검증합니다.
- [ ] focused 또는 disabled 테스트가 남아 있지 않습니다.
- [ ] 실행한 테스트와 harness command evidence를 남겼습니다.

**출력 형식**

완료 보고나 PR note에는 아래 정보를 짧게 포함하세요.

```text
Test coverage:
- Happy-case API integration: <파일 또는 해당 없음과 이유>
- Edge cases: <파일/케이스 또는 더 적은 이유>
- Behavior contract: <무엇을 검증했는지>

Evidence:
- <명령> -> <결과>

Gaps:
- <없음 또는 남은 검증 gap>
```

**주의사항**

- 테스트 개수를 기계적으로 늘리지 마세요. 변경 위험과 관찰 가능한 contract를 기준으로 충분성을 판단합니다.
- production 동작 계약이 바뀌면 구현 전에 OpenSpec change가 필요한지 확인합니다.
- 장기 정책 원문은 이 파일에 복제하지 말고 source of truth 경로를 참조합니다.
