# Repository Guidelines

## Project Structure & Module Organization

StateTrail은 이벤트 기반 시스템의 상태 전이 추적을 위한 Kotlin/Spring 작업 공간입니다. 제품 요구사항은 `docs/PRD.md`에 둡니다. 현재 모듈은 `demo/`이며, 소스는 `demo/src/main/kotlin`, 기본 패키지는 `io.statetrail.demo`입니다. 공통 Gradle 로직은 `buildSrc/src/main/kotlin`, 버전 관리는 `gradle/libs.versions.toml`에서 합니다.

## Architecture & Module Boundaries

핵심 제품 책임과 목표 모듈 경계는 `@ARCHITECTURE.md`를 먼저 확인하세요. 제품 책임과 Gradle 모듈을 1:1로 가정하지 마세요. 모듈별 `AGENTS.md`가 추가되면 해당 모듈 안에서는 더 좁은 지침을 우선합니다.

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

더 구체적인 규칙이 생기기 전까지 커밋 메시지는 간결하고 변경 의도 중심으로 작성하세요. PR에는 해결하려는 문제, 선택한 접근 방식, 검증 결과, 관련 이슈를 포함합니다. 런타임 동작, API 응답, 개발자-facing 출력이 바뀌면 스크린샷이나 로그를 첨부하세요.

## Agent-Specific Instructions

변경은 작고 검토 가능하게 유지하세요. 작업에 꼭 필요하지 않다면 의존성을 추가하지 마세요. 여러 모듈에 공통으로 적용될 동작은 개별 모듈보다 `buildSrc` 컨벤션을 우선 검토하세요. 새 모듈을 만들 때는 `@ARCHITECTURE.md`의 책임 경계와 의존 방향을 먼저 확인하세요.
