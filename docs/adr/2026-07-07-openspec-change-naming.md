# OpenSpec Change 이름 규칙

Status: Accepted

## Context

OpenSpec change 디렉터리 이름이 `d20260706-...`, 긴 `change-YYYY-MM-DD-...`,
짧은 `c-...`, archive 날짜 prefix 형태처럼 서로 다른 규칙으로 섞이면 변경 단위를
빠르게 파악하기 어렵습니다.

날짜 prefix만 사용하는 `YYYY-MM-DD-<slug>` 형식은 읽기 쉽지만, OpenSpec CLI는
change 이름이 문자로 시작해야 하는 제약이 있어 숫자로 시작하는 활성 change id를
거부할 수 있습니다. `change-` 또는 `c-` 같은 별도 prefix는 CLI 제약을 만족하지만
의미 있는 slug가 이미 문자로 시작한다면 불필요한 노이즈입니다.

또한 OpenSpec archive 명령은 archived change 디렉터리명 앞에 archive 날짜를 붙입니다.
활성 change id에 생성 날짜를 넣으면 archive 결과가 `YYYY-MM-DD-YYYY-MM-DD-...`
처럼 날짜를 두 번 담게 됩니다.

## Decision

새 활성 OpenSpec change 디렉터리는 날짜나 별도 prefix 없이 의미 있는 소문자
kebab-case slug만 사용합니다. OpenSpec CLI가 숫자로 시작하는 change 이름을 거부할
수 있으므로 slug는 영문자로 시작해야 합니다. 날짜는 활성 change id에 넣지 않고,
archive 시 OpenSpec이 붙이는 archive 날짜를 사용합니다.

활성 change는 `openspec/changes/<slug>/`처럼 `openspec/changes/`의 직접 하위에 둡니다.
`openspec/changes/change/<slug>/`처럼 중간 `change/` 디렉터리를 두는 구조는 사용하지
않습니다. 임시 루트에서 확인한 결과 nested change는 `openspec validate --changes`와
`openspec validate --all`의 change discovery에 잡히지 않았고,
`openspec status --change change/<slug>`는 slash가 들어간 이름을 invalid change name으로
거부했습니다.

예:

- 활성 change: `add-tracking-evidence-contract`
- archived change: `2026-07-07-add-tracking-evidence-contract`

`openspec/changes/archive/` 아래 디렉터리는 OpenSpec archive 명령이 만든 이력으로
취급합니다. 활성 change naming 규칙을 맞추기 위해 archived package를 수동으로
개명하지 않습니다.

## Consequences

새 change는 OpenSpec CLI의 문자 시작 제약을 만족하면서도 의미 있는 이름만 남깁니다.
Archive 후에는 OpenSpec이 붙인 날짜로 archive 시점을 확인할 수 있습니다.

기존 archived change 이름은 과거 이력으로 보존됩니다. 이름이 섞여 보이더라도 현재
source of truth는 `openspec/specs/`와 활성 change이며, archive 디렉터리명은 새
작업의 naming precedent로 삼지 않습니다.
