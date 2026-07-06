# StateTrail PRD

## 제품 개요

StateTrail은 이벤트 기반 시스템을 위한 상태 전이 추적 및 검증 플랫폼입니다.

이벤트 기반 애플리케이션은 Kafka, RabbitMQ 같은 메시징 시스템에 의존하는 경우가 많지만, 이벤트가 비즈니스 상태를 시간에 따라 어떻게 바꾸었는지 제품 관점에서 명확히 보기 어렵습니다. 브로커 도구는 메시지가 이동했는지를 보여줍니다. 분산 추적 도구는 서비스 호출을 보여줍니다. 워크플로우 엔진은 워크플로우가 엔진 안에서 모델링된 경우 강한 실행 이력을 제공합니다. StateTrail은 그 사이의 빈 영역에 집중합니다. 즉, 어떤 aggregate가 어떤 상태를 지나갔는지, 어떤 이벤트가 그 전이를 만들었는지, 어떤 consumer가 그 전이를 적용했는지, 이벤트 흐름이 어디에서 유효하지 않거나 의심스러워졌는지를 설명합니다.

첫 버전은 self-hosted, developer-focused 제품으로 둡니다. Kotlin/Spring 애플리케이션은 StateTrail SDK를 통해 통합하고, 추적 레코드를 비동기로 발행하며, Git으로 관리되는 상태머신 정의를 사용해 이벤트 처리 동작을 검증합니다. 첫 브로커 통합은 Kafka입니다. RabbitMQ와 다른 메시지 전송 방식은 MVP 요구사항이 아니라 이후 connector 대상입니다.

## 문제 정의

이벤트 소싱 또는 이벤트 기반 시스템을 만드는 팀은 운영 중 다음 질문에 답하기 어렵습니다.

- 지금 `order:123`은 어떤 상태이며, 어떤 이벤트가 그 상태로 이동시켰는가?
- consumer가 이벤트를 받았지만 기대한 상태 전이를 적용하지 못했는가?
- 상태머신을 위반하는 순서로 이벤트가 들어왔는가?
- 결제 실패 이벤트는 유효한 retry 결과인가, 늦게 도착한 evidence인가, 아니면 충돌하는 terminal outcome인가?
- 하나의 비즈니스 흐름에 어떤 서비스와 토픽이 참여했는가?

기존 도구들은 이 문제의 일부만 다룹니다. 브로커 대시보드는 토픽, 파티션, 큐, lag, 처리량에 집중합니다. 분산 추적은 request span과 서비스 지연 시간에 집중합니다. 워크플로우 엔진은 워크플로우가 엔진 안에서 모델링된 경우 강한 이력을 제공합니다. StateTrail은 애플리케이션이 도메인 로직을 계속 소유하면서도, 이벤트 기반 상태 변화를 관측하고 검증하고 설명할 공통 플랫폼이 필요한 시스템을 위한 제품입니다.

## 대상 사용자

- Kotlin/Spring 이벤트 기반 서비스를 만들고 운영하는 backend developer
- 여러 제품 팀을 위한 공통 observability와 reliability 도구를 제공하는 platform engineer
- 이벤트 계약, 상태 전이, cross-service 이벤트 흐름을 리뷰해야 하는 tech lead와 architect
- invalid event, failed consumer, inconsistent aggregate state를 incident 중 진단해야 하는 on-call engineer

## 목표

- 상태 전이, 이벤트 처리 시도, anomaly를 aggregate-first timeline으로 제공합니다.
- consumer가 적용한 전이를 Git-managed 상태머신 정의로 검증합니다.
- producer emission, broker record, consumer handling, state transition, distributed trace를 연결하기에 충분한 metadata를 보존합니다.
- invalid transition, conflicting outcome, handler failure, unclassified event를 원본 evidence를 삭제하거나 재작성하지 않고 드러냅니다.
- 관측된 producer/consumer record에서 flow graph를 파생해 서비스와 토픽을 지나는 이벤트 이동을 inspect할 수 있게 합니다.
- MVP는 observe-first로 둡니다. StateTrail은 기본적으로 문제를 기록하고 설명하며, blocking이나 quarantine은 이후 opt-in 기능으로 확장합니다.

## 비목표

- StateTrail은 Kafka 또는 RabbitMQ 관리 콘솔이 아닙니다.
- StateTrail은 OpenTelemetry, metrics, log aggregation을 대체하지 않습니다.
- MVP에서 StateTrail은 Temporal 또는 Camunda 같은 workflow orchestration engine이 아닙니다.
- StateTrail은 비즈니스 실행 순서를 소유하지 않습니다. 메시지 생산, 소비, retry mechanics는 애플리케이션과 브로커가 계속 소유합니다.
- StateTrail은 raw event payload를 기본 저장하지 않습니다.
- StateTrail은 MVP에서 manual state repair, projection override, branchable history를 제공하지 않습니다.
- StateTrail은 MVP에서 SaaS tenancy, billing, hosted operations를 제공하지 않습니다.

## MVP 범위

MVP는 StateTrail이 실제 이벤트 기반 애플리케이션에서 상태 전이를 신뢰성 있게 설명할 수 있음을 증명해야 합니다.

MVP의 기본 방향은 다음과 같습니다.

- Observe-first: 유효하지 않거나 의심스러운 이벤트는 기본적으로 차단하지 않고 anomaly로 기록합니다.
- Kafka-first: SDK 추적 레코드는 전용 tracking topic으로 발행합니다.
- Kotlin/Spring SDK-first: 첫 통합 경로는 이벤트 생산/소비 지점에 annotation을 사용하는 Spring 애플리케이션입니다.
- Aggregate timeline-first: 기본 UI 진입점은 topic dashboard가 아니라 `order:123` 같은 aggregate입니다.
- Metadata-first: payload 저장을 고려하기 전에 event identity, aggregate identity, ordering key, correlation, causation, trace context, producer, consumer, broker metadata를 수집합니다.

MVP에는 다음이 포함됩니다.

- producer와 consumer instrumentation을 위한 StateTrail SDK
- 전용 Kafka tracking topic 기반 ingestion 경로
- tracking record를 저장하고, 현재 aggregate state를 계산하며, anomaly를 기록하는 server
- Git-managed 상태머신 정의
- aggregate timeline, state machine visualization, derived flow graph, anomaly review를 제공하는 React UI
- 정상 결제, 결제 실패, invalid transition, conflicting outcome 시나리오를 보여주는 order/payment choreography demo

## 제품 의미론

StateTrail은 append-only evidence에서 결정적이고 재현 가능한 상태 해석을 제공해야 합니다. MVP는 aggregate마다 하나의 canonical projection을 사용하고, reject되었거나 ambiguous한 evidence는 그 projection 옆에 함께 기록합니다.

### 전이 권한

Producer-side record와 broker receipt metadata는 aggregate state를 전진시키지 않습니다. Consumer receipt만으로도 aggregate state를 전진시키지 않습니다. 오직 성공한 consumer-applied transition record만 current state projection을 전진시킬 수 있습니다.

상태머신 정의는 aggregate type, legal transition, 필요한 경우 terminal outcome, 그리고 어떤 consumer 또는 handler가 해당 전이를 적용할 권한이 있는지를 선언합니다. Consumer가 자신에게 권한이 없는 aggregate type 또는 transition에 대해 applied transition을 보고하면, StateTrail은 projection을 업데이트하지 않고 해당 evidence를 anomaly로 기록합니다.

여러 consumer가 같은 business event를 관측하는 경우 각 관측은 evidence입니다. 중복 상태 전진은 상태머신이 해당 handler들을 별도 transition authority로 명시적으로 모델링한 경우에만 허용됩니다.

### Projection 순서

Projection 순서는 aggregate별로 정의됩니다. Projection에 참여하는 각 transition은 안정적인 aggregate identity와 ordering key를 가져야 합니다. MVP에서 canonical projection order는 같은 aggregate ordering key로 keying된 successful consumer-applied transition record의 전용 StateTrail tracking topic partition/offset 순서입니다. 따라서 SDK는 projection에 참여하는 transition record를 tracking topic에 발행할 때 aggregate ordering key를 Kafka record key로 사용해야 합니다.

StateTrail은 애플리케이션이 제공할 수 있는 경우 `aggregateVersion` 또는 `stateRevision` 같은 domain sequence도 수집할 수 있습니다. Domain sequence는 stale, duplicate, out-of-order evidence를 감지하는 데 사용하지만, 이후 architecture에서 더 엄격한 projection mode를 명시적으로 도입하기 전까지 MVP canonical order를 대체하지 않습니다.

StateTrail은 같은 aggregate에 대한 두 projecting record가 결정적인 tracking-topic order를 갖지 않거나 선언된 aggregate ordering key를 공유하지 않는 경우 current state를 조용히 선택하면 안 됩니다. Ambiguous ordering은 anomaly로 기록하고, 기록된 metadata로 결정적 순서를 확립할 수 있을 때까지 projection을 업데이트하지 않습니다.

Event time은 진단을 위해 표시하지만 canonical projection을 재정렬하는 데 사용하지 않습니다. Broker position, ingestion time, handler completion evidence는 timeline metadata로 표시합니다.

### Invalid Transition과 Recovery

Invalid transition attempt는 non-projecting evidence입니다. Aggregate timeline과 anomaly inbox에 표시되지만 current state는 마지막 valid projected state로 유지됩니다.

이후 이벤트는 reject된 attempted state가 아니라 마지막 valid projected state를 기준으로 검증합니다. 이전 invalid transition이 받아들여졌을 때만 유효해지는 이후 이벤트는 계속 invalid로 남습니다. Manual repair, projection override, historical branch modeling은 MVP 범위 밖입니다.

### Late Evidence와 Conflicting Outcome

StateTrail은 operation-level identity가 있을 때 late evidence와 conflicting outcome을 구분합니다. Operation identity는 generic `operationId`, `attemptId`, 또는 `paymentAttemptId` 같은 domain-specific identifier일 수 있습니다.

상태머신 정의는 operation에 대한 terminal outcome을 표시할 수 있습니다. 같은 operation identity에서 서로 다른 terminal outcome 두 개가 관측되면 StateTrail은 conflicting outcome anomaly를 기록합니다. Operation identity가 없으면 StateTrail은 낮은 신뢰도의 anomaly evidence를 기록하고, conflicting terminal outcome을 사실로 추론하지 않습니다.

MVP는 의심스러운 evidence를 다음 순서로 분류합니다.

1. Duplicate evidence: 같은 event identity, idempotency key, 또는 같은 operation terminal outcome이 이미 관측된 경우
2. Conflicting terminal outcome: 같은 operation identity에 서로 다른 terminal outcome이 있는 경우
3. Late evidence: record가 current projected domain sequence보다 오래되었거나, 이후 canonical projection이 이미 accepted된 뒤의 non-projecting fact를 설명하는 경우
4. Invalid transition: 마지막 valid projected state에서 허용되지 않는 transition인 경우

Duplicate, conflicting, late evidence는 timeline에 보존됩니다. 해당 evidence가 canonical projection order 안에서 valid, authorized, non-duplicate applied transition이기도 한 경우를 제외하면 current state projection을 업데이트하지 않습니다.

### Definition Versioning

각 validation result는 해당 결과를 만들 때 사용한 state machine definition version과 연결되어야 합니다. Historical validation result는 재현 가능해야 합니다. 새 definition을 기준으로 한 revalidation은 별도 operation 또는 view이며, 과거 anomaly의 의미를 조용히 재작성하면 안 됩니다.

## 핵심 사용자 여정

### 1. Aggregate timeline inspect

Backend developer는 `order:123` 같은 aggregate를 검색합니다. StateTrail은 current state, ordered transition history, producer record, consumer record, handler failure, anomaly를 보여줍니다. Developer는 어떤 이벤트가 aggregate를 현재 상태로 이동시켰고 어떤 서비스가 그 전이를 적용했는지 확인할 수 있습니다.

### 2. Invalid transition 진단

On-call engineer는 anomaly inbox에서 order에 대한 invalid transition을 확인합니다. StateTrail은 previous valid state, invalid transition을 시도한 이벤트, 해당 이벤트를 처리한 consumer, 관련 correlation/causation metadata를 보여줍니다. Valid applied transition이 이후 발생하지 않는 한 projection은 마지막 valid state에 머무릅니다.

### 3. Business flow 이해

Developer는 checkout request에 대한 correlation flow를 엽니다. StateTrail은 관측된 tracking record에서 service, topic, event, consumer graph를 파생합니다. 이 graph는 order event가 payment event로 이어지고, 그 결과가 order service로 돌아오는 흐름을 이해하는 데 도움을 줍니다.

Flow graph는 best-effort이며 evidence 기반입니다. 관측된 이벤트 이동을 설명하지만 완전한 distributed execution history라고 주장하지 않습니다.

### 4. State machine coverage 리뷰

Tech lead는 aggregate type에 대한 Git-managed 상태머신 정의를 리뷰하고 관측된 이벤트와 비교합니다. StateTrail은 unclassified event, 한 번도 발생하지 않은 transition, 상태머신 규칙 누락 또는 오류를 시사하는 anomaly를 드러냅니다.

## 기능 요구사항

- 플랫폼은 producer-side event emission metadata를 기록해야 합니다.
- 플랫폼은 consumer-side event receipt, handling result, applied transition metadata를 기록해야 합니다.
- Consumer-applied transition은 handler가 성공적으로 완료된 뒤에만 confirmed되어야 합니다.
- Producer-side record와 consumer receipt record는 aggregate state를 업데이트하면 안 됩니다.
- 오직 authorized successful consumer-applied transition record만 aggregate state를 업데이트할 수 있습니다.
- Invalid transition은 anomaly로 저장되어야 하며 기본적으로 current state projection을 업데이트하면 안 됩니다.
- Invalid transition 이후의 later transition은 마지막 valid projected state를 기준으로 검증해야 합니다.
- 일치하는 상태머신 정의가 없는 이벤트는 unclassified evidence로 저장해야 합니다.
- Aggregate timeline은 가능한 경우 event time, ingestion time, broker position metadata를 보여줘야 합니다.
- Current state projection은 event time으로 과거 record를 재정렬하지 않고, 같은 aggregate ordering key로 keying된 authorized applied transition record의 tracking topic partition/offset 순서에서 파생해야 합니다.
- Domain sequence가 제공되는 경우 플랫폼은 stale, duplicate, out-of-order evidence 감지에 이를 사용해야 합니다.
- Ambiguous projection ordering은 current state를 조용히 선택하지 않고 anomaly로 보고해야 합니다.
- 플랫폼은 이벤트 간 correlation과 causation link를 지원해야 합니다.
- 플랫폼은 MVP classification order를 사용해 duplicate evidence, conflicting terminal outcome, late evidence, invalid transition을 구분해야 합니다.
- 각 validation result는 해당 validation에 사용한 state machine definition version을 기록해야 합니다.
- UI는 MVP에서 aggregate timeline, state machine view, derived flow graph, anomaly inbox view를 제공해야 합니다.

## 성공 기준

- Developer는 event inheritance hierarchy를 변경하지 않고 SDK를 demo producer/consumer service에 통합할 수 있습니다.
- 정상 order/payment 시나리오는 완전한 aggregate timeline과 최종 valid state를 생성합니다.
- Invalid transition은 anomaly inbox에 표시되고 마지막 valid aggregate state를 덮어쓰지 않습니다.
- Invalid transition 이후의 later event는 마지막 valid projected state를 기준으로 검증됩니다.
- 같은 payment attempt의 conflicting payment outcome은 별도 anomaly로 표시됩니다.
- 같은 payment attempt의 duplicate terminal evidence는 conflicting terminal outcome과 별도로 분류됩니다.
- 더 오래된 domain sequence를 가진 stale event는 late evidence로 표시되고 projection을 업데이트하지 않습니다.
- 같은 aggregate의 ambiguous ordering은 anomaly로 표시되고 current state를 조용히 바꾸지 않습니다.
- Historical validation result는 분류에 사용된 state machine definition version을 식별할 수 있습니다.
- Correlation flow는 demo service와 topic을 가로지르는 derived graph로 inspect할 수 있습니다.
- 새로운 aggregate state machine은 애플리케이션 코드 변경 없이 Git-managed definition으로 추가할 수 있습니다.

## Open Questions

- Observe-only 이후 어떤 policy 기능을 먼저 포함해야 하는가: blocking, quarantine, retry guidance, dead-letter routing, manual review 중 무엇이 우선인가?
- 첫 UI는 aggregate timeline을 anomaly operation보다 더 강조해야 하는가, 아니면 anomaly triage를 기본 landing experience로 두어야 하는가?
- Metadata-first tracking을 넘어 payload support를 어느 정도 제공해야 하며, 어떤 masking 또는 retention rule이 필요한가?
- Kafka 이후 RabbitMQ 지원은 같은 tracking model, connector SPI, 별도 integration package 중 어떤 방식으로 도입해야 하는가?
- 첫 stable contract로 지원할 state machine definition format은 YAML only, JSON only, 또는 둘 다인가?
- 새 state machine definition 기준 revalidation은 어떤 operator workflow로 trigger해야 하는가?
