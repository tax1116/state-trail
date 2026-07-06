# StateTrail

StateTrail은 이벤트 기반 시스템을 위한 상태 전이 추적 및 검증 플랫폼입니다.

Kafka 같은 메시징 시스템 위에서 애플리케이션이 이벤트를 생산하고 소비할 때, StateTrail은 어떤 이벤트가 어떤 aggregate의 상태를 바꾸었는지, 어떤 consumer가 전이를 적용했는지, 어떤 전이가 유효하지 않았는지를 추적하는 것을 목표로 합니다.

## 현재 상태

이 저장소는 StateTrail의 제품 요구사항과 Kotlin/Spring 기반 구현을 함께 정리하는 초기 작업 공간입니다.

- 제품 기준 문서: [docs/PRD.md](docs/PRD.md)
- 첫 구현 방향: Kafka-first, Kotlin/Spring SDK-first, observe-first
- 현재 모듈: `demo`
- 패키지 네임스페이스: `io.statetrail`

## 기술 스택

- **Language:** Kotlin 2.2.21
- **Framework:** Spring Boot 4.0.3
- **Build:** Gradle 9.4.0 (Kotlin DSL)
- **Java:** 21
- **Test:** JUnit 5 (`spring-boot-starter-test`)
- **Lint:** ktlint

## 빌드 명령어

```bash
./gradlew build
./gradlew check
./gradlew :demo:bootRun
./gradlew :demo:test
```

## 프로젝트 구조

```text
.
├── buildSrc/              # Gradle convention plugin
├── demo/                  # 초기 Spring Boot demo module
├── docs/
│   └── PRD.md             # StateTrail 제품 요구사항
├── gradle/                # Gradle wrapper/catalog
├── build.gradle.kts
└── settings.gradle.kts
```

## 빌드 컨벤션

빌드 로직은 `buildSrc/src/main/kotlin/`의 convention plugin으로 관리합니다.

| 플러그인 | 설명 |
|---|---|
| `global-convention` | Kotlin JVM, ktlint, Java 21 toolchain, kotlin-logging, JUnit 5, repository 설정 |
| `spring-boot-convention` | Spring Boot application module용 convention |
| `spring-jar-convention` | Spring Boot BOM을 사용하는 library module용 convention |

## 다음 정리 후보

- `ARCHITECTURE.md` 작성
- SDK/server/UI/demo module 분리 전략 확정
- README의 실행 예시를 실제 demo scenario에 맞게 갱신
