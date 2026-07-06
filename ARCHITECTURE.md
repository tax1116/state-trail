# StateTrail Architecture Notes

## Purpose

이 문서는 에이전트와 기여자가 StateTrail의 제품 책임과 목표 모듈 경계를 같은 기준으로 이해하기 위한 참고 문서입니다. 최종 서비스 분해나 배포 구조를 확정하는 문서가 아닙니다.

제품 책임, Gradle 모듈, 내부 레이어를 1:1로 보지 마세요. 실제 모듈이 생기기 전까지 이 문서는 루트 `AGENTS.md`의 세부 참조 역할을 합니다.

## Product Responsibilities

- SDK: 사용자 애플리케이션 안에서 tracking evidence를 만듭니다. 상태머신 검증, projection 계산, anomaly 최종 분류를 수행하지 않습니다.
- Transport / Connector: SDK가 만든 evidence를 Runtime으로 전달합니다. MVP의 첫 통로는 Kafka tracking topic입니다.
- Runtime: evidence를 수집, 해석, 저장하고 조회 API를 제공하는 중앙 실행부입니다. 단순 HTTP 서버로 취급하지 마세요.
- UI: Runtime API를 소비해 aggregate timeline, state machine view, flow graph, anomaly review를 보여줍니다. 현재 Kotlin/Gradle 모듈 설계에서는 별도 frontend 영역으로 보고 세부 경계는 추후 확정합니다.
- Demo: StateTrail을 적용하는 사용자 애플리케이션 샘플입니다. 내부 정책이나 Runtime 로직을 구현하지 않습니다.

Runtime 내부의 `Ingestion`, `Engine`, `Storage`, `Query/API`는 제품 책임 이름입니다. 독립 모듈이나 독립 서비스로 바로 분리하지 말고, Runtime 안의 입력 처리, 유스케이스, 핵심 규칙, 외부 연결 구현으로 나눠 생각하세요.

## Target Module Boundaries

아래 목록은 기본 책임 경계이지 최종 서비스 분해 약속이 아닙니다.

- `contracts`: SDK와 Runtime이 공유하는 tracking evidence 계약, identity, metadata 모델만 둡니다.
- `sdk-core`: framework-neutral SDK API와 evidence 생성 모델을 둡니다.
- `sdk-spring`: Spring annotation, AOP, interceptor 같은 Kotlin/Spring 통합 표면을 둡니다.
- `sdk-kafka`: SDK core 로직이 아니라 Transport / Connector 구현입니다. SDK가 만든 evidence를 Kafka tracking topic으로 발행합니다.
- `runtime-domain`: evidence 의미론, 상태머신 규칙, projection 규칙, anomaly 분류 규칙을 둡니다.
- `runtime-application`: ingestion, validation, projection, query use case와 repository/access interface를 둡니다.
- `runtime-infrastructure`: Kafka consumer, persistence implementation, definition loader, REST controller 같은 외부 연결 구현만 둡니다. Query 판단과 domain 규칙은 `runtime-application` 또는 `runtime-domain`에 둡니다.
- `runtime-app`: Spring Boot 실행, configuration, module wiring을 담당합니다.
- `demo`: order/payment 같은 acceptance scenario를 보여주는 사용자 애플리케이션으로 둡니다.

## Dependency Direction

의존 방향은 안쪽으로만 흐르게 유지하세요.

```text
runtime-app -> runtime-infrastructure -> runtime-application -> runtime-domain -> contracts
sdk-spring -> sdk-core -> contracts
sdk-kafka -> sdk-core -> contracts
demo -> sdk-spring / sdk-kafka
```

`runtime-domain`은 Spring, Kafka, database 구현을 몰라야 합니다. `runtime-application`은 외부 구현을 직접 알지 않고 interface를 정의합니다. `runtime-infrastructure`는 Kafka, database, HTTP 같은 바깥 기술을 안쪽 use case와 interface에 연결합니다. SDK는 Runtime의 projection, anomaly, state machine 해석 모델에 의존하지 않습니다.

## When To Add Module-Local AGENTS.md

실제 모듈이 생기고 루트 지침보다 좁은 규칙이 필요할 때만 모듈별 `AGENTS.md`를 추가합니다. 예를 들어 `runtime-domain/AGENTS.md`에는 외부 기술 의존 금지, `demo/AGENTS.md`에는 샘플 애플리케이션 책임만 적습니다.
