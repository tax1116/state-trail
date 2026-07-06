## 1. 저장소 로컬 가이드

- [x] 1.1 API happy-case, edge-case, behavior-focused coverage, 검증 기대사항을 안내하되 OpenSpec/ADR/architecture를 source of truth로 참조하는 `.codex/skills/state-trail-test-writing/SKILL.md`를 추가합니다.
- [x] 1.2 StateTrail 전용 Spec, ADR, architecture, harness, LogQL, fallback-review check를 안내하되 장기 정책 원문을 중복하지 않는 `.codex/skills/state-trail-code-review/SKILL.md`를 추가합니다.
- [x] 1.3 스킬을 추가한 뒤 전용 `.codex/agents/state-trail-code-reviewer.toml`이 필요한지 판단하고, skill layer만으로 부족할 때만 추가합니다.

## 2. 검증 스크립트

- [x] 2.1 fast/strict mode matrix를 소유하는 canonical runner로 `scripts/verify-harness.sh`를 추가합니다.
- [x] 2.2 fast 로컬 검증 wrapper로 `scripts/pre-commit-verify.sh`를 추가하고 `scripts/verify-harness.sh --mode fast`를 호출하게 합니다.
- [x] 2.3 strict CI 검증 wrapper로 `scripts/ci-verify.sh`를 추가하고 `scripts/verify-harness.sh --mode strict`를 호출하게 합니다.
- [x] 2.4 필수 Gradle build/static 검증 명령을 실행하는 `scripts/verify-build.sh`를 추가합니다.
- [x] 2.5 필수 테스트 실행, 실패 전파, focused/disabled 테스트 패턴, 설정된 테스트 경로처럼 기계적 조건을 검증하는 `scripts/verify-tests.sh`를 추가합니다.
- [x] 2.6 fast static 모드와 live-required 항목이 있을 때만 strict live-query를 강제하는 `scripts/verify-logql.sh`를 추가합니다.
- [x] 2.7 모든 스크립트가 저장소 루트에서 실행 가능하고, 실패 메시지가 명확하며, 필수 실패에서 non-zero로 종료되게 합니다.
- [x] 2.8 stub command, PATH override, 또는 dry-run fixture를 사용해 하위 검증 실패가 non-zero와 실패 check 이름으로 전파되는지 확인하는 smoke check를 추가합니다.

## 3. Codex Hook 통합

- [x] 3.1 현재 저장소 로컬 Codex hook convention을 확인하고 올바른 hook 파일 또는 설정 형식을 선택합니다.
- [x] 3.2 `scripts/pre-commit-verify.sh`를 호출하는 Codex pre-commit hook을 추가합니다.
- [x] 3.3 build 또는 test 실패가 commit 완료 전에 Codex pre-commit hook 경로를 실패시키는지 검증합니다.
- [x] 3.4 `.codex/hooks.json`에서 PreToolUse wrapper를 등록하고, `git commit` payload만 pre-commit 경로를 실행하는지 `verification.md`에 기록합니다.

## 4. CI 통합

- [x] 4.1 `.github/workflows/ci.yml`이 `scripts/ci-verify.sh`를 호출하도록 갱신합니다.
- [x] 4.2 CI가 strict harness 경로를 통해 계속 `./gradlew check`를 실행하는지 확인합니다.
- [x] 4.3 향후 strict LogQL live-query check에 필요한 CI 환경 요구사항을 문서화합니다.

## 5. LogQL 하네스

- [x] 5.1 저장소 로컬 경로 아래에 초기 LogQL query-definition convention을 추가합니다.
- [x] 5.2 fast validator가 확인할 수 있는 sample 또는 자리표시자가 없는 query definition을 최소 하나 추가합니다.
- [x] 5.3 strict mode에서 live-required query definition 또는 대표 로그 fixture가 없으면 live LogQL check가 설정되지 않았음을 명시적으로 보고하게 합니다.
- [x] 5.4 live log evidence가 필요하지만 Loki를 사용할 수 없을 때 strict mode가 명시적으로 실패하는지 보장합니다.
- [x] 5.5 `demo-startup` query를 참조하는 optional 대표 로그 fixture를 추가하고 fast/strict 정적 검증으로 확인합니다.

## 6. 검증과 OpenSpec 완료

- [x] 6.1 fast local harness를 실행하고 `verification.md`에 결과를 기록합니다.
- [x] 6.2 `./gradlew check` 또는 strict CI harness를 실행하고 `verification.md`에 결과를 기록합니다.
- [x] 6.3 OpenSpec change artifact를 검증하고 `verification.md`에 결과를 기록합니다.
- [x] 6.4 구현이 승인되면 `quality-harness` delta spec을 `openspec/specs/`에 sync합니다.
- [x] 6.5 완료된 OpenSpec change를 archive합니다.
