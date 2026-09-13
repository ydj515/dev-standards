# dev-standards

여러 저장소에서 재사용할 개발 표준, 아키텍처 규칙과 AI agent context를 조합하고 배포하는
중앙 원본 저장소입니다.

각 프로젝트는 필요한 언어, 프레임워크, 아키텍처와 도구만 선택합니다. `dev-standards`는 그
선택을 하나의 styleguide와 원본 구조를 보존한 개별 문서로 만들며, 초기 도입에 필요한 설정
템플릿도 제공합니다.

## 주요 기능

- **Composable standards**: 언어, 아키텍처, 프레임워크, 빌드 도구, 품질 도구와 런타임을
  독립적으로 선택합니다.
- **Architecture defaults**: Spring, FastAPI, React와 Next.js에는 기본 profile을 제공하고,
  소비 저장소가 명시적으로 교체하거나 비활성화할 수 있습니다.
- **Safe bootstrap**: 기존 설정을 덮어쓰지 않고 누락된 agent 진입 파일과 선택한 설정만
  최초 생성합니다.
- **Pull request delivery**: [`ci-workflows`](https://github.com/ydj515/ci-workflows)가 Release를
  확인하고 변경사항을 소비 저장소의 pull request로 전달합니다.

## 동작 방식

1. 소비 저장소가 `.dev-standards/config.yml`에서 적용할 모듈을 선택합니다.
2. Release의 `compose.sh`가 선택된 표준을 조합합니다.
3. 소비 저장소에는 `.dev-standards/styleguide.md`와 `.dev-standards/standards/**`가 생성됩니다.
4. 선택적으로 `bootstrap.sh`가 lint, format, build와 agent 설정의 시작점을 복사합니다.

`dev-standards`는 표준과 템플릿의 원본을 소유합니다. 소비 저장소의 설정과 bootstrap 이후의
파일은 해당 프로젝트가 소유합니다.

## 빠른 시작

소비 저장소에 `.dev-standards/config.yml`을 만듭니다. 다음은 React + TypeScript 예시입니다.

```yaml
version: 1
languages: [typescript]
frameworks: [react-ts]
tools:
  - eslint
  - frameworks/react-ts/eslint-plugin-react-hooks
  - prettier
  - frameworks/react-ts/dependency-cruiser
  - frameworks/react-ts/vitest
  - pnpm
runtimes: [mise]
```

이 저장소를 clone한 환경에서는 다음 명령으로 표준을 로컬에서 조합할 수 있습니다.

```sh
./scripts/compose.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --output /path/to/project/.dev-standards/styleguide.md \
  --modules-dir /path/to/project/.dev-standards/standards
```

초기 설정 파일도 필요하면 bootstrap을 한 번 실행합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project
```

운영 저장소에서는 로컬 실행 대신
[`ci-workflows` 소비 가이드](https://github.com/ydj515/ci-workflows/blob/main/docs/sync-dev-standards.md)에
따라 주기적인 pull request 동기화를 구성합니다.

## 지원 범위

| 구분 | 제공 항목 예시 |
| --- | --- |
| 언어 | Go, Java, Kotlin, Python, TypeScript |
| 아키텍처 | Domain-oriented, Layered Clean, Feature Layered, Feature-Sliced, Route Feature |
| 프레임워크 | Spring, FastAPI, React, Next.js, MUI, Tailwind, Bootstrap, Thymeleaf |
| 품질 도구 | golangci-lint, Detekt, Checkstyle, PMD, SpotBugs, Ruff, Pyright, ESLint, Prettier, Vitest |
| 빌드·런타임 | Gradle, Maven, pnpm, mise |

## 문서

- [문서 전체 보기](docs/README.md)
- [선택 설정과 architecture profile](docs/configuration.md)
- [설정 Bootstrap과 agent 연동](docs/bootstrap.md)
- [GitHub Actions 소비 설정](https://github.com/ydj515/ci-workflows/blob/main/docs/sync-dev-standards.md)

## 개발

변경 후 다음 검증을 실행합니다.

```sh
./scripts/test-compose.sh
./scripts/test-bootstrap.sh
git diff --check
```
