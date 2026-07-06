# Repository Guidelines

## Project Structure & Module Organization

StateTrail은 이벤트 기반 시스템의 상태 전이 추적을 위한 Kotlin/Spring 작업 공간입니다. 제품 요구사항은 `docs/PRD.md`에 둡니다. 현재 모듈은 `demo/`이며, 소스는 `demo/src/main/kotlin`, 기본 패키지는 `io.statetrail.demo`입니다. 공통 Gradle 로직은 `buildSrc/src/main/kotlin`, 버전 관리는 `gradle/libs.versions.toml`에서 합니다.

## Architecture & Module Boundaries

핵심 제품 책임과 목표 모듈 경계는 `@ARCHITECTURE.md`를 먼저 확인하세요. 제품 책임과 Gradle 모듈을 1:1로 가정하지 마세요. 모듈별 `AGENTS.md`가 추가되면 해당 모듈 안에서는 더 좁은 지침을 우선합니다.

## Documentation, SDD & ADR

오래 남기는 문서는 Spec과 ADR 중심으로 유지합니다. 현재 제품 동작 계약은 `openspec/specs/`에서 확인하고, 오래 남는 아키텍처와 프로세스 결정 근거는 `docs/adr/`에서 확인하세요. `openspec/changes/<change>/`는 진행 중인 Spec Change를 리뷰하고 구현하기 위한 패키지이며, 해당 변경을 작업할 때만 읽습니다. `openspec/changes/archive/`는 활성 지침이 아니라 이력으로 취급합니다. `docs/research/`는 ignored 로컬 리서치와 초안 공간이며, 결론이 Spec 또는 ADR로 승격되기 전까지 저장소 지침으로 취급하지 마세요.

동작 계약이 바뀌면 Spec을 추가하거나 수정하고, 이후 작업을 제약할 아키텍처 또는 프로세스 결정이 생기면 ADR을 추가하세요. 단순 구현 메모, 작업 목록, 리서치 덤프, 내부 리팩터는 기본적으로 Spec이나 ADR로 만들지 않습니다. ADR 파일명은 `docs/adr/README.md`의 `yyyyMMddHHmmss-<slug>.md` 규칙을 따릅니다.

작업을 시작할 때 먼저 변경 유형을 분류하세요. 관찰 가능한 제품 동작이나 외부 계약이 바뀌면 `openspec/changes/<change>/`에 리뷰 가능한 Spec Change를 만든 뒤 구현합니다. 구현은 TDD로 진행하고, 완료 후 delta spec을 `openspec/specs/`에 반영한 다음 change를 archive로 이동합니다. 이후 작업을 제약할 아키텍처, 프로세스, 운영상 결정이 생기면 `docs/adr/`에 ADR을 추가합니다. 단순 내부 리팩터나 작은 버그 수정처럼 동작 계약과 장기 결정이 바뀌지 않는 작업은 기존 테스트와 코드 변경만으로 처리합니다.

## Build, Test, and Development Commands

- `./gradlew check`: CI와 동일한 검증을 실행합니다.
- `./gradlew build`: 전체 모듈을 빌드하고 검증 태스크를 실행합니다.
- `./gradlew :demo:bootRun`: Spring Boot 데모 애플리케이션을 실행합니다.
- `./gradlew :demo:test`: `demo` 모듈 테스트만 실행합니다.
- `./gradlew ktlintFormat`: Kotlin 및 Kotlin DSL 스타일 문제를 자동 정리합니다.

## Coding Style & Naming Conventions

Kotlin 2.2, Java 21 toolchain, Spring Boot 기반 `buildSrc` 컨벤션을 따르세요. `.editorconfig` 기준에 맞춰 LF 줄바꿈, 4칸 들여쓰기, 후행 공백 제거, 파일 끝 개행을 유지합니다. Kotlin 패키지는 `io.statetrail` 하위에 둡니다. 클래스와 객체는 `PascalCase`, 함수와 프로퍼티는 `camelCase`, Gradle convention plugin ID는 소문자 하이픈 형식을 사용합니다.

## Testing Guidelines

테스트는 `spring-boot-starter-test`를 통해 JUnit 5를 사용합니다. 도메인 로직은 작은 단위 테스트를 우선하고, Spring Boot 테스트는 프레임워크 설정이나 빈 연결 검증이 필요할 때만 사용하세요. 테스트는 `src/test/kotlin` 아래 프로덕션 패키지와 동일한 구조로 배치합니다.

## Commit & Pull Request Guidelines

브랜치 관리는 GitHub Flow를 따르되 `dev`를 기본 통합 브랜치로 둡니다. `main`은 릴리스가 필요할 때만 병합하는 안정 브랜치로 유지합니다. 기능 개발은 `feat/<topic>` 브랜치에서 진행합니다. 큰 단위 프로젝트는 `integration/<topic>` 통합 브랜치를 만들고, 관련 기능 브랜치는 여기에 먼저 병합한 뒤 완료 시 `dev`로 올립니다. 커밋 메시지는 간결하고 변경 의도 중심으로 작성하세요. PR에는 해결하려는 문제, 선택한 접근 방식, 검증 결과, 관련 이슈를 포함합니다. 런타임 동작, API 응답, 개발자-facing 출력이 바뀌면 스크린샷이나 로그를 첨부하세요.

## Agent-Specific Instructions

변경은 작고 검토 가능하게 유지하세요. 작업에 꼭 필요하지 않다면 의존성을 추가하지 마세요. 여러 모듈에 공통으로 적용될 동작은 개별 모듈보다 `buildSrc` 컨벤션을 우선 검토하세요. 새 모듈을 만들 때는 `@ARCHITECTURE.md`의 책임 경계와 의존 방향을 먼저 확인하세요.
