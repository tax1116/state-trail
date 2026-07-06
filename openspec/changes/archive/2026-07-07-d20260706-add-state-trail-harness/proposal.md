## Why

StateTrail에는 에이전트 작업, 로컬 커밋, CI가 같은 검증 계약을 따르도록 하는 저장소 전용 품질 하네스가 필요합니다. 프로젝트가 아직 초기 단계이므로, 하네스는 빌드, 테스트, 리뷰, 로그 evidence 누락을 잡되 로컬 개발 흐름을 지나치게 무겁거나 깨지기 쉽게 만들면 안 됩니다.

## What Changes

- Codex pre-commit 정책, 재사용 가능한 검증 스크립트, 테스트 작성 가이드, 코드리뷰 가이드, LogQL 검증을 포함하는 StateTrail 품질 하네스 capability를 추가합니다.
- 커밋 시점의 빌드 및 테스트 검증을 강제하는 정책 트리거로 Codex pre-commit hook을 정의합니다.
- Codex hook, CI, 수동 실행이 함께 호출할 수 있는 저장소 로컬 스크립트를 공통 검증 엔진으로 정의하고, mode별 검증 계약은 하나의 canonical runner에 둡니다.
- 로컬 커밋은 실용적으로 유지하고 CI는 더 강한 evidence를 강제할 수 있도록 fast 모드와 strict 모드를 구분합니다.
- 전역 reviewer/test-engineer 역할을 복제하지 않고, StateTrail 전용 코드리뷰 및 테스트 작성 스킬을 정의합니다.
- LogQL 검증은 정적 쿼리 검증에서 시작하고, live-required 쿼리가 선언된 경우 strict 모드에서 실제 Loki 조회를 강제하는 경로를 정의합니다.

## Capabilities

### New Capabilities

- `quality-harness`: Codex hook, CI 스크립트, 코드리뷰 가이드, 테스트 작성 가이드, LogQL 검증에 대한 관찰 가능한 개발 품질 계약을 정의합니다.

### Modified Capabilities

- 없음.

## Impact

- 새 `quality-harness` capability에 대한 OpenSpec artifact가 추가됩니다.
- 이후 구현에서는 저장소 로컬 `.codex/` 스킬과 hook 정의가 추가됩니다.
- 이후 구현에서는 재사용 가능한 `scripts/` 검증 진입점이 추가됩니다.
- 이후 구현에서는 GitHub Actions가 strict 검증 하네스를 호출하도록 갱신됩니다.
- 이 변경에는 production API, SDK, runtime, storage, UI 동작 변경이 포함되지 않습니다.
