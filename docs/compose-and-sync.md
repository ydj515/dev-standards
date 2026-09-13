# 표준 조합과 동기화

`dev-standards`는 표준과 템플릿의 단일 원본입니다. 소비 저장소는 원본을 직접 수정하지 않고
`.dev-standards/config.yml`에서 필요한 모듈을 선택합니다.

## 저장소 구성

| 경로 | 역할 |
| --- | --- |
| `standards/` | 공통, 언어, 아키텍처, 프레임워크와 도구 표준 원본 |
| `templates/` | 소비 저장소가 최초 채택할 수 있는 설정 파일 시작점 |
| `scripts/compose.sh` | 선택된 표준의 병합본과 개별 문서 생성 |
| `scripts/bootstrap.sh` | agent 진입 파일과 선택 설정의 비파괴적 최초 복사 |
| `scripts/test-compose.sh` | 조합과 stale module 제거 계약 검증 |
| `scripts/test-bootstrap.sh` | template mapping, 충돌과 멱등성 검증 |

## 로컬 조합

`compose.sh`는 Bash와 Python 3 표준 라이브러리만 사용합니다.

```sh
./scripts/compose.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --output /path/to/project/.dev-standards/styleguide.md \
  --modules-dir /path/to/project/.dev-standards/standards \
  --source-ref "dev-standards@main"
```

생성 결과는 다음과 같습니다.

```text
.dev-standards/
├─ config.yml                  # 소비 저장소 소유
├─ styleguide.md               # 선택 문서를 합친 agent 진입점
└─ standards/                 # 같은 선택 문서의 개별 원본
   ├─ base.md
   ├─ languages/
   ├─ architectures/
   ├─ frameworks/
   ├─ build-tools/
   ├─ tools/
   └─ runtime/
```

AI agent가 단일 파일만 읽을 때는 `styleguide.md`를 사용하고, 코드 리뷰와 변경 이력에서는
`standards/**`의 개별 파일을 사용합니다. 두 산출물은 같은 선택 목록에서 생성됩니다.

## GitHub Actions 동기화

운영 저장소에서는 [`ci-workflows`의 reusable workflow](https://github.com/ydj515/ci-workflows/blob/main/docs/sync-dev-standards.md)를
사용합니다. 기본 구성은 다음 생명주기를 가집니다.

1. 정기 실행 시 `dev-standards`의 최신 정식 Release를 해석합니다.
2. 소비 저장소의 선택 설정으로 표준을 조합합니다.
3. 관리 산출물과 resolved commit, checksum을 `.dev-standards/lock.json`에 기록합니다.
4. 변경이 있으면 `automation/dev-standards-sync` branch의 pull request를 생성하거나
   갱신합니다.

상시 동기화는 `.dev-standards/styleguide.md`, `.dev-standards/standards/**`, 상태 파일과 선택한
Gemini 병합본만 관리합니다. `.dev-standards/config.yml`과 bootstrap 이후 설정 파일은 소비
저장소가 소유합니다.

기존 `.dev-standards.yml`과 `.dev-standards/guide.md` 구조에서 전환한다면
[디렉터리 구조 마이그레이션](migrations/dev-standards-directory-layout.md)을 따릅니다.
