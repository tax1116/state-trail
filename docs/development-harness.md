# StateTrail Development Harness

이 문서는 StateTrail 저장소 품질 하네스의 Codex hook, CI, strict LogQL live-query 환경 요구사항을 정리합니다. 장기 동작 계약의 source of truth는 `openspec/specs/`와 활성 OpenSpec change이며, 이 문서는 개발자가 실행 표면을 찾기 위한 안내입니다.

## Codex Hook Convention

Codex runtime이 읽는 repo-local hook surface는 `.codex/hooks.json`입니다. 이 하네스는 `PreToolUse` wrapper인 `.codex/hooks/pre-tool-use-pre-commit`을 등록하고, wrapper가 Bash tool의 `git commit` command payload만 골라 `.codex/hooks/pre-commit`을 실행합니다. Hook command는 `git rev-parse --show-toplevel`로 저장소 루트를 확인한 뒤 wrapper를 실행하므로 저장소 하위 디렉터리에서 tool을 호출해도 같은 검증 경로를 사용합니다.

선택 이유는 다음과 같습니다.

- `hooks.json`은 `omx setup`이 공유 소유하는 Codex native hook 표면과 같은 형식을 사용합니다.
- PreToolUse payload는 `tool_name: "Bash"`와 `tool_input.command`를 확인하므로 매 tool 실행마다 build/test가 돌지 않습니다.
- hook wrapper는 POSIX shell로 유지되어 Codex hook 실행 환경과 로컬 shell 양쪽에서 이해하기 쉽습니다.
- 검증 로직은 hook에 두지 않고 `scripts/pre-commit-verify.sh`에 위임합니다.
- `scripts/pre-commit-verify.sh`가 실패하면 hook도 같은 실패 상태로 종료되어 commit 완료를 차단합니다.

hook 호출 흐름은 다음과 같습니다.

```text
.codex/hooks.json
  -> PreToolUse .codex/hooks/pre-tool-use-pre-commit
       -> Bash tool + git commit command만 통과
       -> .codex/hooks/pre-commit
            -> scripts/pre-commit-verify.sh
                 -> scripts/verify-harness.sh --mode fast
```

`scripts/pre-commit-verify.sh`가 아직 없거나 실행할 수 없으면 hook은 명시적인 오류와 함께 실패해야 합니다. 스크립트가 실행 권한을 갖지 않아도 hook은 `bash scripts/pre-commit-verify.sh`로 한 번 더 시도합니다.

## CI Harness

GitHub Actions는 strict 검증의 세부 명령을 workflow 안에 복제하지 않고 `scripts/ci-verify.sh`를 호출합니다. strict harness runner는 `scripts/ci-verify.sh -> scripts/verify-harness.sh --mode strict` 경로에서 `./gradlew check`를 포함해야 합니다.

CI 호출 흐름은 다음과 같습니다.

```text
.github/workflows/ci.yml
  -> scripts/ci-verify.sh
       -> scripts/verify-harness.sh --mode strict
            -> ./gradlew check
```

workflow는 실행 전에 `gradlew`와 `scripts/*.sh`에 실행 권한을 부여합니다. 실제 검증 명령의 추가, 삭제, 순서 변경은 CI workflow가 아니라 `scripts/` 하네스 안에서 관리하세요.

## Strict LogQL Live-Query CI Env

fast LogQL 검증은 live Loki service를 요구하지 않는 정적 검증이어야 합니다. strict mode에서는 live-required query definition 또는 대표 로그 fixture가 선언된 경우에만 live query가 필수입니다.

strict live-query check가 활성화되면 CI는 다음 실행 환경을 제공해야 합니다.

- `logcli`: Loki live query를 실행할 CLI입니다. strict live-required query가 있으면 CI image 또는 별도 setup step에서 설치해야 합니다.
- `STATE_TRAIL_LOKI_URL`: StateTrail harness가 우선 사용하는 Loki HTTP API base URL입니다. 예: `https://loki.example.com`
- `LOKI_ADDR` 또는 `LOKI_URL`: `STATE_TRAIL_LOKI_URL`을 쓰지 않는 환경에서 사용할 수 있는 호환 Loki URL입니다.
- `STATE_TRAIL_LOGQL_SINCE`: live evidence를 조회할 시간 범위입니다. 예: `15m`. 지정하지 않으면 하네스가 기본값을 사용합니다.
- `LOKI_TENANT_ID`: multi-tenant Loki를 사용할 때 전달할 tenant ID입니다. 단일 tenant 환경에서는 비워둘 수 있습니다.
- `LOKI_BEARER_TOKEN`: bearer token 인증을 사용할 때 필요한 secret입니다.
- `LOKI_USERNAME` 및 `LOKI_PASSWORD`: basic auth를 사용할 때 필요한 secret입니다. bearer token을 사용하면 필요하지 않습니다.

인증 방식은 bearer token 또는 basic auth 중 하나만 사용하세요. live-required query가 있는데 Loki URL, `logcli`, 또는 필요한 인증 secret이 없으면 strict harness는 LogQL live check를 건너뛰지 않고 실패해야 합니다.

live-required query definition 또는 대표 로그 fixture가 없으면 strict harness는 `no live LogQL checks configured`처럼 live check가 설정되지 않았음을 보고하고 통과할 수 있습니다.

## Current Boundary

현재 하네스는 stable entrypoint인 `scripts/pre-commit-verify.sh`, `scripts/ci-verify.sh`, `scripts/verify-harness.sh`를 제공합니다. script는 build/test 실행 실패, focused/disabled test pattern, LogQL query definition metadata처럼 기계적으로 검증 가능한 조건을 담당합니다.

API happy-case 통합 테스트 충분성, edge-case 선택, 구현 세부 결합 여부는 script가 자동 판정하지 않고 `state-trail-test-writing` 및 `state-trail-code-review` guidance와 reviewer 판단으로 남깁니다. 일반적인 StateTrail 테스트 작성/보완은 `.codex/agents/state-trail-test-engineer.toml`의 경량 테스트 agent를 우선 사용하고, 테스트 인프라/flaky/high-risk 검증은 global `test-engineer` 또는 `architect`로 올립니다. 일반적인 StateTrail 리뷰는 `.codex/agents/state-trail-code-reviewer.toml`의 경량 리뷰 agent를 우선 사용하고, 보안/아키텍처/high-risk 변경은 global `code-reviewer` 또는 `architect`로 올립니다. 현재 sample LogQL definition은 `live: optional`이므로 strict harness는 live query가 설정되지 않았음을 보고하고 통과할 수 있습니다. `live: required` definition이 추가되면 strict harness는 Loki URL, `logcli`, 필요한 인증 환경변수가 없을 때 실패해야 합니다.
