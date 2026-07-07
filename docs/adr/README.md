# Architecture Decision Records

ADR은 StateTrail의 오래 남는 아키텍처와 프로세스 결정을 기록합니다.

이후 작업을 안내해야 하고 결정 이유가 중요한 경우 ADR을 작성합니다. 예를
들어 모듈 경계, 문서 정책, persistence 전략, integration contract, 운영
제약, 오래 남는 트레이드오프가 있는 선택이 여기에 해당합니다.

일시적인 구현 메모, 작업 목록, 리서치 덤프, 관찰 가능한 제품 동작 계약에는
ADR을 사용하지 않습니다. 제품 동작은 `openspec/specs/`에 둡니다. 진행 중인
Spec Change 자료는 `openspec/changes/<change>/` 아래에 둡니다.

각 ADR은 짧게 유지하고 다음 형식을 사용합니다.

- 파일명: `YYYY-MM-DD-<slug>.md`
- `Status`: Proposed, Accepted, Superseded, Deprecated 중 하나
- `Context`: 결정을 만들게 된 배경, 제약, 문제
- `Decision`: 선택한 정책 또는 아키텍처
- `Consequences`: 트레이드오프, 후속 의무, 읽기 지침

저장소를 읽을 때 동작은 `openspec/specs/`에서 확인하고, 오래 남는 결정
근거는 이 디렉터리에서 확인합니다. `openspec/changes/archive/`는 활성
지침이 아니라 이력으로 취급합니다.
