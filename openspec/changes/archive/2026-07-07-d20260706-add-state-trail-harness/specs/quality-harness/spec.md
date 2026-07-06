## ADDED Requirements

### Requirement: Shared Verification Entrypoints

저장소 품질 하네스는 Codex hook, CI, 개발자가 저장소 루트에서 호출할 수 있는 repo-local script 진입점을 MUST 제공해야 합니다. stable entrypoint는 `scripts/verify-harness.sh`, `scripts/pre-commit-verify.sh`, `scripts/ci-verify.sh`입니다.

#### Scenario: Developer runs local verification
- **WHEN** 개발자가 저장소 루트에서 `scripts/pre-commit-verify.sh` 또는 `scripts/verify-harness.sh --mode fast`를 호출합니다
- **THEN** 스크립트는 필요한 fast build, test, harness check를 실행하고 필수 check 중 하나라도 실패하면 non-zero로 종료합니다

#### Scenario: CI runs strict verification
- **WHEN** CI가 저장소 루트에서 `scripts/ci-verify.sh` 또는 `scripts/verify-harness.sh --mode strict`를 호출합니다
- **THEN** 스크립트는 strict harness check를 실행하고 strict-mode requirement 중 하나라도 실패하면 non-zero로 종료합니다

### Requirement: Verification Mode Matrix

저장소 품질 하네스는 fast 모드와 strict 모드의 check matrix를 하나의 canonical runner에서 MUST 정의해야 합니다.

#### Scenario: Fast mode runs local checks
- **WHEN** `scripts/verify-harness.sh --mode fast`가 실행됩니다
- **THEN** harness는 build/static verification, test execution, fast LogQL static validation을 실행합니다

#### Scenario: Strict mode runs CI checks
- **WHEN** `scripts/verify-harness.sh --mode strict`가 실행됩니다
- **THEN** harness는 전체 Gradle check, required test execution, strict-mode harness check, LogQL validation을 실행합니다

### Requirement: Codex Pre-Commit Gate

저장소 품질 하네스는 필수 build 또는 test 검증이 실패하면 commit 완료를 차단하는 Codex pre-commit hook을 MUST 정의해야 합니다.

#### Scenario: Build fails before commit
- **WHEN** Codex pre-commit hook이 실행되고 필수 build 검증이 실패합니다
- **THEN** hook은 commit 완료를 막고 실패한 검증 명령을 보고합니다

#### Scenario: Tests fail before commit
- **WHEN** Codex pre-commit hook이 실행되고 필수 test 검증이 실패합니다
- **THEN** hook은 commit 완료를 막고 실패한 검증 명령을 보고합니다

### Requirement: CI Strict Harness

저장소 품질 하네스는 전체 Gradle check와 변경된 동작에 필요한 strict harness check를 포함하는 strict CI 모드를 MUST 제공해야 합니다.

#### Scenario: CI executes the harness
- **WHEN** pull request 또는 보호 branch push에 대해 GitHub Actions가 실행됩니다
- **THEN** CI는 임시 workflow command에만 의존하지 않고 strict harness 진입점을 호출합니다

#### Scenario: Strict mode fails
- **WHEN** CI에서 strict harness check 중 하나라도 실패합니다
- **THEN** CI job은 실패하고 어떤 harness check가 실패했는지 드러냅니다

### Requirement: API Test Coverage Guidance

저장소 품질 하네스는 API 변경에 대해 깨지기 쉬운 구현 세부 coverage를 강제하지 않으면서 behavior-focused test를 요구하는 StateTrail 테스트 작성 guidance를 MUST 정의해야 합니다.

#### Scenario: API behavior is added or changed
- **WHEN** 변경이 관찰 가능한 API 동작을 추가하거나 변경합니다
- **THEN** 구현은 HTTP-style client 또는 프로젝트가 승인한 equivalent를 통해 API를 실행하는 happy-case API integration test를 최소 하나 포함합니다

#### Scenario: API edge conditions exist
- **WHEN** API 동작에 의미 있는 validation, state, authorization, ordering, error edge condition이 있습니다
- **THEN** 구현은 집중된 edge-case test 두세 개를 포함하거나, 더 적은 테스트로 충분한 이유를 PR 설명, change note, 또는 review note에 기록합니다

#### Scenario: Change has no API surface
- **WHEN** 변경이 순수 내부 변경이고 관찰 가능한 API 동작이 없습니다
- **THEN** 구현은 가짜 API test를 추가하지 않고 영향받는 contract에 대한 equivalent behavior-focused coverage를 포함합니다

### Requirement: Test Harness Enforcement Boundary

저장소 품질 하네스는 script가 자동 강제할 수 있는 기계적 테스트 조건과 reviewer가 판단해야 하는 테스트 충분성 조건을 MUST 분리해야 합니다.

#### Scenario: Test script enforces mechanical checks
- **WHEN** `scripts/verify-tests.sh`가 실행됩니다
- **THEN** script는 테스트 실행 실패, 금지된 focused/disabled 테스트 패턴, 설정된 테스트 경로 존재 여부처럼 기계적으로 검증 가능한 조건만 강제합니다

#### Scenario: Reviewer evaluates test adequacy
- **WHEN** API happy-case, edge-case 충분성, 또는 구현 세부 결합 여부가 자동 판정하기 어렵습니다
- **THEN** StateTrail test-writing/code-review guidance와 reviewer가 변경된 behavior와 기록된 evidence를 기준으로 충분성을 판단합니다

### Requirement: StateTrail Code Review Guidance

저장소 품질 하네스는 reviewer가 generic code-review workflow와 함께 적용할 수 있는 StateTrail 전용 code-review guidance를 MUST 정의해야 합니다. 이 guidance는 OpenSpec, ADR, architecture 문서를 source of truth로 참조해야 하며 장기 정책 원문을 중복 정의하면 안 됩니다.

#### Scenario: Review checks project contracts
- **WHEN** reviewer가 StateTrail 변경을 평가합니다
- **THEN** reviewer는 변경을 승인하기 전에 적용 가능한 OpenSpec, ADR, architecture guidance를 확인합니다

#### Scenario: Review checks harness evidence
- **WHEN** reviewer가 behavior, tests, hooks, CI, logs에 영향을 주는 StateTrail 변경을 평가합니다
- **THEN** reviewer는 관련 harness command가 실행됐는지 또는 validation gap이 명시적으로 보고됐는지 확인합니다

#### Scenario: Review checks fallback behavior
- **WHEN** 변경이 fallback, compatibility, best-effort 동작을 도입합니다
- **THEN** reviewer는 fallback이 failure evidence를 보존하고 root cause를 숨기지 않는지 검증합니다

### Requirement: LogQL Verification Modes

저장소 품질 하네스는 fast static 모드와 conditional strict live-query 모드를 갖는 LogQL 검증을 MUST 정의해야 합니다.

#### Scenario: Fast LogQL verification runs
- **WHEN** fast harness verification에 LogQL check가 포함됩니다
- **THEN** harness는 live Loki service를 요구하지 않고 LogQL query definition과 required metadata를 검증합니다

#### Scenario: Strict LogQL verification runs with Loki
- **WHEN** strict harness verification이 live-required query definition 또는 대표 로그 fixture 때문에 live log evidence를 요구하고 Loki를 사용할 수 있습니다
- **THEN** harness는 승인된 LogQL 실행 경로를 통해 Loki를 query하고 expected evidence가 없으면 실패합니다

#### Scenario: Strict LogQL verification has no live checks configured
- **WHEN** strict harness verification이 실행되지만 live-required query definition 또는 대표 로그 fixture가 없습니다
- **THEN** harness는 live LogQL check가 설정되지 않았음을 명시적으로 보고하고 live query 없이 통과할 수 있습니다

#### Scenario: Loki is unavailable in strict mode
- **WHEN** strict harness verification이 live-required query definition 또는 대표 로그 fixture 때문에 live log evidence를 요구하지만 Loki를 사용할 수 없습니다
- **THEN** harness는 live log check를 조용히 건너뛰지 않고 명시적인 메시지와 함께 실패합니다
