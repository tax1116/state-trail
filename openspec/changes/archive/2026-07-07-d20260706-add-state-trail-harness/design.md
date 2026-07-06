## Context

StateTrail은 초기 단계의 Kotlin/Spring 작업 공간입니다. 현재 저장소에는 `demo` 모듈 하나가 있고, CI는 `./gradlew check`를 실행합니다. 전역 Codex/OMX 표면에는 이미 generic `code-reviewer`, `test-engineer`, `code-review` workflow가 있지만, OpenSpec/ADR 규율, API 통합 테스트 coverage, 균형 잡힌 edge-case 테스트, Codex pre-commit 정책, 로그 evidence 검증 같은 StateTrail 전용 기대사항은 담겨 있지 않습니다.

이 하네스의 규칙은 StateTrail의 문서 모델, 모듈 경계, 개발 workflow와 직접 연결되므로 저장소 로컬로 둡니다. 다만 가능한 곳에서는 전역 agent 역할을 재사용합니다.

## Goals / Non-Goals

**Goals:**

- Codex pre-commit 정책을 로컬 커밋 시점 gate로 정의합니다.
- 저장소 로컬 스크립트를 hook, CI, 수동 실행이 공유하는 검증 엔진으로 정의합니다.
- 빠른 로컬 검증 모드와 strict CI 검증 모드를 구분합니다.
- StateTrail 전용 테스트 작성 스킬과 코드리뷰 스킬을 정의합니다.
- Loki 기반 테스트 로그가 준비되면 live query 기반으로 확장할 수 있는 LogQL 검증 경로를 정의합니다.

**Non-Goals:**

- `~/.codex` 아래에 전역 스킬이나 전역 agent를 만들지 않습니다.
- 기본 로컬 커밋마다 Docker, Loki, live log query를 요구하지 않습니다.
- 깨지기 쉬운 구현 세부 테스트를 강제하는 광범위한 테스트 개수 규칙을 추가하지 않습니다.
- production runtime, SDK, storage, API, UI 동작을 변경하지 않습니다.
- 전역 `code-reviewer` 또는 `test-engineer`를 대체하지 않고, 그 위에 StateTrail 규칙을 조합합니다.

## Decisions

### Codex hook은 정책을 트리거하고, scripts는 검증을 실행합니다

pre-commit gate는 저장소 로컬 스크립트를 호출하는 Codex hook으로 둡니다. hook은 언제 검증이 필요한지를 결정하고, scripts는 어떤 검증을 실행할지를 정의합니다.

mode별 검증 계약은 `scripts/verify-harness.sh --mode fast|strict`에 둡니다. `scripts/pre-commit-verify.sh`와 `scripts/ci-verify.sh`는 각각 fast 모드와 strict 모드를 호출하는 얇은 wrapper입니다. 내부 helper script는 구현 편의를 위한 세부 구조이며, 장기 계약의 중심은 canonical runner와 두 wrapper입니다.

기각한 대안: 모든 검증 로직을 hook 안에 직접 넣는 방식입니다. 이 방식은 CI 재사용을 어렵게 만들고, 로컬 workflow와 원격 workflow 사이에 검증 로직 중복을 만듭니다.

예상 구조:

```text
Codex pre-commit hook
  -> scripts/pre-commit-verify.sh
       -> scripts/verify-harness.sh --mode fast

GitHub Actions
  -> scripts/ci-verify.sh
       -> scripts/verify-harness.sh --mode strict
```

### scripts를 CI 계약으로 사용합니다

하네스가 생기면 GitHub Actions는 `scripts/ci-verify.sh`를 호출해야 합니다. 이 스크립트는 strict 진입점이며 `./gradlew check`를 포함해야 합니다.

기각한 대안: GitHub Actions만 전체 검증 계약을 아는 방식입니다. 이 방식은 로컬 검증과 agent 동작이 CI와 드리프트하게 만듭니다.

### 로컬은 빠르게, CI는 strict하게 검증합니다

로컬 pre-commit 검증은 빌드와 테스트 실패를 차단해야 하지만, live Loki 검증은 환경이 이미 준비되어 있지 않다면 기본 opt-in으로 둡니다. CI strict 모드는 더 무거운 evidence를 요구할 수 있습니다.

기각한 대안: 모든 커밋마다 로컬 Loki를 요구하는 방식입니다. 이 방식은 로그 검증을 강하게 만들지만 일반 개발 흐름을 너무 무겁게 만듭니다.

기본 mode matrix는 다음과 같습니다.

| Check | fast mode | strict mode |
|---|---|---|
| Build/static verification | 필수 | 필수 |
| Test execution | 필수 | 필수 |
| Test adequacy judgment | skill/reviewer 판단 | skill/reviewer 판단 |
| LogQL static validation | 필수 | 필수 |
| LogQL live query | live-required 쿼리가 있으면 opt-in 실행 | live-required 쿼리가 있으면 필수 |

`verify-tests.sh`는 테스트 실행, 실패 전파, 금지된 focused/disabled 테스트 패턴, 설정된 테스트 경로 존재 여부처럼 기계적으로 확인 가능한 조건을 담당합니다. API happy-case와 edge-case 충분성, 구현 세부 결합 여부, 더 적은 테스트로 충분한 이유는 `state-trail-test-writing` 및 `state-trail-code-review` guidance와 reviewer가 판단합니다.

### 전용 native agent보다 skill을 먼저 추가합니다

StateTrail 전용 코드리뷰 및 테스트 작성 규칙은 먼저 `.codex/skills/` 항목으로 둡니다. 전용 native `state-trail-code-reviewer` agent는 skill layer만으로 부족하다고 확인될 때만 추가합니다. repo-local skill은 정책 원문을 새로 복제하지 않고, OpenSpec/ADR/architecture 문서를 source of truth로 링크하고 적용 절차를 안내하는 얇은 실행 표면으로 유지합니다.

기각한 대안: 전역 `code-reviewer`와 `test-engineer` prompt를 저장소에 복제하는 방식입니다. 이 방식은 전역 개선사항과의 유지보수 드리프트를 만듭니다.

### LogQL은 두 단계로 정의합니다

초기 LogQL 하네스는 쿼리 정의와 필수 metadata를 검증합니다. strict live query는 live-required query definition 또는 대표 로그 fixture가 선언된 경우에만 필수입니다. strict 모드에서 live-required 대상이 없으면 harness는 `no live LogQL checks configured`처럼 명시적으로 보고하고 통과할 수 있습니다. live-required 대상이 있는데 Loki를 사용할 수 없으면 실패해야 합니다.

기각한 대안: observability가 완전히 구현될 때까지 LogQL을 미루는 방식입니다. 이 방식은 로그 evidence 테스트 계약 정의를 늦추고, 이후 통합을 임시방편으로 만들 가능성이 큽니다.

## Risks / Trade-offs

- Pre-commit이 느려질 수 있습니다 -> 기본 hook 경로는 빠르게 유지하고 live Loki 검증은 strict 모드로 둡니다.
- Codex 버전에 따라 hook 형식이 바뀔 수 있습니다 -> hook 로직은 얇게 유지하고 검증 동작은 scripts에 격리합니다.
- 테스트 규칙이 너무 경직될 수 있습니다 -> API happy-case 통합 테스트는 API 동작이 있을 때만 요구하고, edge-case guidance는 risk 기반으로 유지합니다.
- 로그가 생기기 전에 LogQL 검증이 형식적인 검증에 머물 수 있습니다 -> 정적 검증에서 시작하되, live-required 쿼리 또는 테스트 로그 fixture가 선언되는 순간 strict 모드에서 live 검증을 필수로 전환합니다.
- 스킬이 전역 reviewer guidance를 중복할 수 있습니다 -> StateTrail 스킬은 정책 원문을 복제하지 않고 OpenSpec/ADR/architecture 링크와 적용 절차를 제공합니다.

## Migration Plan

1. 저장소 로컬 StateTrail 코드리뷰 스킬과 테스트 작성 스킬을 추가합니다.
2. `scripts/verify-harness.sh --mode fast|strict`를 canonical runner로 추가하고, mode matrix를 이 runner에 둡니다.
3. `scripts/pre-commit-verify.sh`를 호출하는 Codex pre-commit hook을 추가합니다.
4. GitHub Actions가 `scripts/ci-verify.sh`를 호출하도록 갱신합니다.
5. LogQL 쿼리 정의 convention과 fast 검증을 추가합니다.
6. live-required LogQL query 또는 Loki 기반 테스트 로그가 준비되면 strict live LogQL 검증이 필수로 실패/성공을 판정하게 합니다.
7. skill 기반 guidance만으로 부족할 때만 전용 StateTrail reviewer agent를 추가합니다.

하네스는 additive 변경이므로 rollback은 단순합니다. Codex hook 호출을 제거하거나 로컬에서 non-blocking으로 바꾸고, GitHub Actions job은 `./gradlew check`로 되돌립니다. scripts는 수동 실행용으로 남길 수 있습니다.

## Open Questions

- 정확한 Codex hook 파일 형식은 구현 시점에 현재 저장소 로컬 Codex hook convention을 확인한 뒤 선택합니다.
- API 통합 테스트 client는 테스트 대상 모듈에 맞춥니다. 후보는 MockMvc, RestClient, WebTestClient 또는 프로젝트가 승인한 다른 client입니다.
- LogQL 쿼리 파일 형식은 assert할 가치가 있는 첫 관찰 가능 동작이 로그를 내보낼 때 선택합니다.
