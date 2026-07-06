# 검증 기록

이 파일은 `d20260706-add-state-trail-harness` 변경의 검증 근거를 기록합니다. 새 검증을 실행하면 기존 근거를 덮어쓰지 말고 정확한 명령, 날짜, 결과를 이어서 기록합니다.

## 2026-07-07 리뷰 피드백 반영

- 통과: `bash -n scripts/*.sh`
- 통과: `sh -n .codex/hooks/pre-commit .codex/hooks/pre-tool-use-pre-commit`
- 통과: `python3 -m json.tool .codex/hooks.json >/dev/null`
- 통과: `.codex/hooks.json`의 PreToolUse command는 `git rev-parse --show-toplevel`로 저장소 루트를 확인한 뒤 `.codex/hooks/pre-tool-use-pre-commit`를 실행하도록 등록했습니다.
- 통과: `{"tool_name":"Bash","tool_input":{"command":"git status"}}`와 `{"tool_name":"Bash","tool_input":{"command":"echo git commit"}}` PreToolUse payload는 pre-commit 검증을 실행하지 않고 종료했습니다.
- 통과: `{"tool_name":"Bash","tool_input":{"command":"git commit -m review-feedback"}}` PreToolUse payload는 `.codex/hooks/pre-commit`, `./gradlew classes`, `./gradlew test`, fast LogQL 검증을 실행하고 0으로 종료했습니다.
- 통과: `.codex/hooks/pre-tool-use-pre-commit --self-test`는 `git add .\ngit commit -m ...` 및 CRLF multi-line payload를 commit으로 탐지하고, `echo git commit`과 quoted 문자열은 no-op으로 유지했습니다.
- 통과: `{"tool_name":"Bash","tool_input":{"command":"git add .\ngit commit -m review-feedback"}}` PreToolUse payload는 저장소 하위 디렉터리에서도 `.codex/hooks/pre-commit`, `./gradlew classes`, `./gradlew test`, fast LogQL 검증을 실행하고 0으로 종료했습니다.
- 통과: `scripts/smoke-verify-harness.sh`는 stub build 실패를 non-zero 상태와 실패 check 이름 `build`로 전파했습니다.
- 통과: `scripts/verify-logql.sh --mode fast`는 정적 query definition 검증을 통과했습니다.
- 통과: `scripts/verify-logql.sh --mode strict`는 `observability/logql/fixtures/demo-startup.logql-fixture` 대표 fixture metadata를 검증하고, live LogQL check가 설정되지 않았음을 명시적으로 보고한 뒤 통과했습니다.
- 통과: 임시 `observability/logql/fixtures/tmp-live-required.logql-fixture`에 `# live: required`를 선언하면 `STATE_TRAIL_LOKI_URL`, `LOKI_ADDR`, `LOKI_URL`이 없는 strict LogQL 검증이 실패했습니다. 검증 후 임시 fixture는 제거했습니다.
- 통과: `scripts/verify-harness.sh --mode strict`는 `./gradlew check`, `./gradlew test`, strict LogQL 검증, `scripts/smoke-verify-harness.sh`를 실행했습니다.
- 통과: `scripts/ci-verify.sh`는 strict harness 경로를 통해 `./gradlew check`, `./gradlew test`, strict LogQL fixture 검증, hook self-test를 포함한 smoke 검증을 실행하고 통과했습니다.
- 통과: `openspec validate --changes d20260706-add-state-trail-harness`는 1개 change를 통과시키고 실패 0개를 보고했습니다.
