# StateTrail LogQL Query Definition

LogQL definition은 `observability/logql/queries/*.logql`에 두고 `scripts/verify-logql.sh`로 검증합니다.

각 파일에는 다음 metadata가 필요합니다.

```logql
# name: stable-kebab-case-name
# description: concise purpose for the query
# live: optional|required
{app="state-trail-demo"} |= "Started"
```

`live: optional` definition은 fast/strict 모드에서 정적으로 검증합니다. `live: required` definition은 strict 모드에서 `logcli`로 Loki query까지 실행해야 합니다. Loki endpoint는 `STATE_TRAIL_LOKI_URL`, `LOKI_ADDR`, `LOKI_URL` 중 하나로 설정합니다.

대표 로그 fixture는 `observability/logql/fixtures/*.logql-fixture`에 추가할 수 있습니다. Fixture metadata에는 `# name`, `# description`, `# query: <query-name>`, `# live: optional|required`가 필요하며, `# query` 값은 기존 query definition의 `# name`과 일치해야 합니다. `live: required` fixture는 참조한 query에 대해 strict live 검증을 활성화합니다.
