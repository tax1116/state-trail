# StateTrail LogQL 대표 Fixture

대표 fixture는 `observability/logql/fixtures/*.logql-fixture`에 두고 `scripts/verify-logql.sh`로 검증합니다.

각 fixture에는 기존 query definition의 `# name`과 연결되는 metadata가 필요합니다.

```text
# name: stable-kebab-case-fixture-name
# description: concise representative log evidence purpose
# query: existing-query-name
# live: optional|required
2026-07-06T12:00:00Z app=state-trail-demo Started StateTrail demo application
```

`live: optional` fixture는 정적으로 검증합니다. `live: required` fixture는 strict 모드에서 참조한 query를 Loki에 실행하도록 요구하며, live-required query definition과 동일하게 `STATE_TRAIL_LOKI_URL`, `LOKI_ADDR`, `LOKI_URL` 설정을 사용합니다.
