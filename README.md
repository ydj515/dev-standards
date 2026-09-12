# dev-standards

이 저장소는 **여러 프로젝트에서 공통으로 사용하는 개발 표준과 AI 어시스턴트(Gemini, Claude, Antigravity 등) 지침을 단일 원본으로 중앙 관리**하기 위한 레포지토리입니다.

---

## ci-workflows와의 관계

이 저장소는 규칙의 **단일 원본(Source of Truth)**을 관리합니다.

실제 각 서비스 레포지토리에서는 이 저장소를 직접 수정하지 않고 `ci-workflows`의
`sync-dev-standards.yml`을 통해 필요한 표준을 병합한 `.dev-standards/styleguide.md`와
원본 계층을 보존한 `.dev-standards/standards/**`로 동기화합니다.

1. `dev-standards`에서 `standards/**`, `templates/**` 원본을 관리합니다.
2. 각 레포지토리는 `.dev-standards/config.yml` 설정을 통해 필요한
   언어/프레임워크/도구를 선택합니다.
3. CI 워크플로(`sync-dev-standards.yml`) 또는 로컬 스크립트(`scripts/compose.sh`)가
   선택 문서를 병합본과 개별 파일 두 형태로 생성합니다.
4. 최초 설정이 필요하면 `scripts/bootstrap.sh`가 선택된 설정 템플릿만 소비 저장소에
   복사합니다. 애플리케이션 소스와 프레임워크 디렉터리는 만들지 않습니다.

---

## 디렉토리 구조

```text
dev-standards/
├─ standards/
│  ├─ base.md                  # 공통 개발 및 코드 리뷰 원칙 (Persona, 안전, 설계)
│  ├─ languages/               # 언어별 표준 (go, java, kotlin, python, typescript)
│  ├─ architectures/           # 애플리케이션 구조와 의존 방향 profile
│  ├─ frameworks/              # 프레임워크별 표준 (spring, fastapi, react-ts, next-ts 등)
│  ├─ build-tools/             # 빌드 도구 표준 (gradle, maven)
│  ├─ tools/                   # 언어/프레임워크별 정적 분석, 포맷, 패키지 도구
│  │  ├─ languages/            # go, java, kotlin, python, typescript
│  │  └─ frameworks/           # react-ts, next-ts 등 프레임워크 전용 도구
│  └─ runtime/                 # 런타임 환경 (mise)
├─ templates/                  # 프로젝트 생성 시 복사해 사용하는 템플릿 파일
│  ├─ agents/                  # 루트 AGENTS.md, CLAUDE.md, GEMINI.md 시작점
│  ├─ editorconfig/            # 범용 표준 .editorconfig
│  ├─ biome/                   # TypeScript Biome 설정
│  ├─ dependency-cruiser/      # React module dependency 규칙
│  ├─ eslint/                  # ESLint flat config 예시
│  ├─ golangci-lint/           # golangci-lint 설정 예시
│  ├─ gradle/                  # Gradle Version Catalog 및 품질 도구 설정
│  ├─ maven/                   # Maven pom.xml 예시
│  ├─ mise/                    # 언어별 mise.toml 예시
│  ├─ pnpm/                    # pnpm 및 workspace 설정
│  ├─ pyright/                 # Pyright 타입 검사 설정
│  ├─ prettier/                # Prettier 설정과 ignore
│  ├─ ruff/                    # Ruff lint 및 format 설정
│  ├─ vitest/                  # React test와 V8 coverage 설정
│  └─ ...
└─ scripts/
   ├─ compose.sh               # Bash와 Python 표준 라이브러리 기반 조합 스크립트
   ├─ test-compose.sh          # 병합본과 개별 표준 동기화 검증
   ├─ bootstrap.sh             # 선택 설정을 기존 파일 덮어쓰기 없이 최초 복사
   └─ test-bootstrap.sh        # bootstrap 계약 검증
```

---

## 소비 설정 (`.dev-standards/config.yml`)

소비 프로젝트는 `.dev-standards/config.yml`에서 적용할 모듈을 선택합니다. 설정 원본,
병합본과 개별 문서를 하나의 namespace 아래에 둡니다.

```yaml
version: 1
base: true
languages:
  - kotlin
  - typescript
frameworks:
  - react-ts
  - tailwind
builds:
  - gradle
tools:
  - eslint
  - frameworks/react-ts/eslint-plugin-react-hooks
  - prettier
  - frameworks/react-ts/dependency-cruiser
  - frameworks/react-ts/vitest
  - pnpm
runtimes:
  - mise
```

- `base`: `true`일 때 공통 원칙 포함
- `languages`: 적용할 프로그래밍 언어 목록 (e.g. `[kotlin]`, `[kotlin, typescript]`)
- `architectures`: 적용할 아키텍처 profile 목록. 생략하면 프레임워크 기본값을 적용하고,
  `[]`는 자동 기본값을 끄며, 하나 이상 명시하면 추론값을 대체
- `frameworks`: `spring`, `fastapi`, `react-ts`, `next-ts`, `tailwind`, `mui` 등 다중 선택
- `builds`: `gradle`, `maven` 등 다중 선택
- `tools`: `eslint`, `golangci-lint`, `ruff`, `pyright`, `prettier`, `biome`, `pnpm`,
  `detekt`, `checkstyle`, `pmd`, `spotbugs`, `frameworks/react-ts/eslint-plugin-react-hooks`,
  `frameworks/react-ts/dependency-cruiser`, `frameworks/react-ts/vitest`,
  `frameworks/next-ts/eslint-config-next` 등 다중 선택
- `runtimes`: `mise` 등 다중 선택

언어 가이드는 공통 로직을 다른 문법으로 번역하는 수준이 아니라 각 생태계의 타입 모델,
오류·자원 수명 주기, 동시성과 composition 관용구를 따릅니다. 아키텍처 profile은
애플리케이션 package 구조와 의존 방향을 소유하고, 프레임워크 가이드는 해당 구조를
router, controller, component와 persistence 같은 구체적인 실행 모델에 연결합니다. 작은
프로젝트는 논리적 경계를 유지하는 범위에서 물리적 파일과 package를 합칠 수 있습니다.

`architectures`를 생략했을 때의 기본값은 다음과 같습니다.

| 선택 | 자동 architecture | 기본 방향 |
| --- | --- | --- |
| `frameworks: [spring]` | `layered-clean` | `presentation → application → domain ← infrastructure` |
| `frameworks: [fastapi]` | `feature-layered` | 기능 package 내부의 HTTP/application/domain/adapter 분리 |
| `frameworks: [react-ts]` | `feature-sliced` | `app → pages → widgets → features → entities → shared` |
| `frameworks: [next-ts]` | `route-feature` | App Router 경계와 server/client feature 분리 |

언어 선택만으로 architecture를 자동 추론하지 않습니다. `domain-oriented`는 Go 전용
문서가 아니며 명시적으로 선택합니다. Go에서는 업무 package와 adapter로 평탄화하고,
Spring에서는 `order/{presentation,application,domain,infrastructure}`처럼 bounded
context 내부 계층으로 구현합니다. Spring의 자동 기본값은 단순성과 기존 생태계 관례를
위해 `layered-clean`으로 유지합니다.

`react-ts`와 `next-ts`를 함께 선택하면 더 구체적인 Next.js의 `route-feature`만 자동
적용합니다. React SPA에서 Next.js로 전환하는 중 Feature-Sliced 구조를 계속 유지하려면
`architectures: [feature-sliced]`로 명시합니다.

Go, Java, Kotlin, Python과 일반 TypeScript는 언어만으로 애플리케이션 종류를 알 수
없으므로 architecture를 자동 선택하지 않습니다. Bootstrap, MUI, Tailwind와 Thymeleaf도
상위 애플리케이션 구조를 바꾸지 않고 선택된 framework profile 안에서 UI 책임만
보강합니다.

`languages`, `architectures`, `frameworks`, `builds`, `tools`, `runtimes`는 block 또는 inline 배열로
지정하며 선언 순서대로 조합합니다. TypeScript formatter는 `prettier`와 `biome` 중
하나만 선택합니다.

도구 문서는 `standards/tools/languages/<language>/` 또는
`standards/tools/frameworks/<framework>/`에 둡니다. 이름이 전체 도구 트리에서 유일하면
`ruff`처럼 짧게 선택하고, 같은 이름이 둘 이상이면 `languages/python/ruff`처럼 qualified
selector를 사용합니다.

`base`와 여섯 배열은 모두 선택 항목입니다. `base`를 생략하면 기본 가이드를 포함하고,
제외하려면 `base: false`로 지정합니다. architecture 이외의 배열은 생략하거나 `[]`로 두면
해당 계층을 조합하지 않습니다. architecture는 생략과 빈 배열의 의미가 다릅니다.

Spring을 bounded context 우선 DDD 구조로 바꾸는 예:

```yaml
version: 1
languages: [kotlin]
frameworks: [spring]
architectures: [domain-oriented]
```

Go 서비스에 domain-oriented 구조를 적용하는 예:

```yaml
version: 1
languages: [go]
architectures: [domain-oriented]
```

Spring을 사용하지만 architecture profile은 자동 적용하지 않는 예:

```yaml
version: 1
languages: [kotlin]
frameworks: [spring]
architectures: []
```

Python 프로젝트 예시:

```yaml
version: 1
languages: [python]
tools: [ruff, pyright]
runtimes: [mise]
```

일반 TypeScript 프로젝트는 `tools: [eslint, prettier, pnpm]` 조합이나
`tools: [biome, pnpm]` 조합을 사용할 수 있습니다. React 프로젝트는 전자에
`frameworks/react-ts/eslint-plugin-react-hooks`, `frameworks/react-ts/dependency-cruiser`,
`frameworks/react-ts/vitest`를 추가합니다. Next.js 프로젝트는
React Hooks 규칙을 포함하는 `frameworks/next-ts/eslint-config-next`를 선택하고 같은
`eslint.config.mjs`에서 일반 TypeScript 규칙과 병합합니다.

Java/Kotlin 품질 도구와 React/TypeScript 도구는 다음 책임으로 대응합니다. 이는 도구의
내부 분석 방식이 동일하다는 뜻이 아니라 CI에서 같은 실패 범위를 소유한다는 뜻입니다.

| Java/Kotlin 생태계 | React / TypeScript 대응 | 역할 |
| --- | --- | --- |
| Detekt / PMD | ESLint | 정적 분석, 코드 품질, 버그 패턴 탐지 |
| Checkstyle / ktlint | ESLint + Prettier | 코딩 컨벤션 + 포맷팅 |
| ArchUnit | dependency-cruiser / eslint-plugin-boundaries / Nx module boundaries | 아키텍처/레이어 의존성 검증 |
| SpotBugs | ESLint + TypeScript compiler | 잠재 버그/타입 오류 |
| JaCoCo | Vitest/Jest + V8/Istanbul coverage | 테스트 커버리지 |

---

## 로컬 가이드 생성

Ruby와 YAML gem 없이 Bash와 Python 3 표준 라이브러리만으로 실행할 수 있습니다.

```sh
./scripts/compose.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --output /path/to/project/.dev-standards/styleguide.md \
  --modules-dir /path/to/project/.dev-standards/standards \
  --source-ref "dev-standards@main"
```

소비 저장소의 동기화 결과는 다음과 같습니다.

```text
.dev-standards/
├─ config.yml                  # 소비 저장소가 작성하고 소유
├─ styleguide.md              # 선택 문서를 병합한 단일 진입점
└─ standards/                 # 같은 선택 문서의 개별 원본
   ├─ base.md
   ├─ languages/
   ├─ architectures/
   ├─ frameworks/
   ├─ build-tools/
   ├─ tools/
   └─ runtime/
```

`styleguide.md`는 AI 도구가 한 파일만 읽을 때 사용하고, 코드 리뷰와 변경 이력에서는
`standards/**`의 개별 파일을 사용합니다. 두 산출물은 같은 선택 목록에서 생성합니다.

기존 `.dev-standards.yml`과 `.dev-standards/guide.md` 구조에서 전환하는 저장소는
[디렉터리 구조 마이그레이션 가이드](docs/migrations/dev-standards-directory-layout.md)를
따릅니다.

## 설정 Bootstrap

`bootstrap.sh`는 agent 진입 파일과 `.dev-standards/config.yml`에서 선택한 실제 설정
파일을 소비 저장소에 복사합니다. 명령 자체가 명시적인 최초 채택 단계이며, 복사 이후에는
소비 저장소가 파일을 소유합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project
```

기존 프로젝트 설정을 건드리지 않고 누락된 agent 진입 파일만 만들려면
`--agents-only`를 사용합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project \
  --agents-only
```

선택과 출력 파일의 기본 매핑은 다음과 같습니다.

| 선택 | 소비 저장소 출력 |
| --- | --- |
| bootstrap 공통 | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` |
| 하나 이상의 `languages` | `.editorconfig` |
| `builds: [gradle]` | `gradle/libs.versions.toml` |
| `builds: [maven]` | `pom.xml` |
| `tools: [detekt]` | `config/detekt/detekt.yml` |
| `tools: [checkstyle]` | `config/checkstyle/checkstyle.xml` |
| `tools: [pmd]` | `config/pmd/ruleset.xml` |
| `tools: [spotbugs]` | `config/spotbugs/exclude-filter.xml` |
| `tools: [golangci-lint]` | `.golangci.yml` |
| `tools: [eslint]` | `eslint.config.mjs` |
| `tools: [frameworks/react-ts/dependency-cruiser]` | `.dependency-cruiser.cjs` |
| `tools: [prettier]` | `prettier.config.mjs`, `.prettierignore` |
| `tools: [biome]` | `biome.json` |
| `tools: [pnpm]` | `pnpm-workspace.yaml` |
| `tools: [ruff]` | `ruff.toml` |
| `tools: [pyright]` | `pyrightconfig.json` |
| `tools: [frameworks/react-ts/vitest]` | `vitest.config.ts` |
| `runtimes: [mise]` | `mise.toml` |

framework별 ESLint 도구는 기존 `eslint.config.mjs`에 preset을 병합해야 하므로 독립 파일을
자동 복사하지 않습니다. `runtimes: [mise]` bootstrap도 resolution 결과인 `mise.lock`을
생성하지 않습니다. 버전 자리표시자를 확정한 뒤 `mise lock`을 실행하고 lockfile을 소비
저장소에서 관리합니다.

mise 프로필은 `builds`의 `gradle`/`maven` 또는 `languages`의 `go`/`python`/`typescript`에서
추론합니다. 후보가 여러 개거나 없으면 임의로 합치지 않고 실패하므로 하나를 지정합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project \
  --mise-profile typescript
```

- 대상 파일이 없으면 복사합니다.
- 대상 파일이 템플릿과 같으면 변경 없이 성공합니다.
- 대상 파일이 이미 있고 내용이 다르면 어떤 파일도 복사하기 전에 실패합니다.
- 기존 `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`는 예외적으로 덮어쓰거나 실패시키지 않고 보존하며,
  공유 표준 참조를 직접 확인하라는 경고를 출력합니다.
- `--dry-run`은 복사 계획과 충돌만 검증합니다.
- React의 `src/app`, `pages`, `features`나 Spring package 등 소스 구조는 생성하지 않습니다.
- Gradle 품질 도구 Kotlin DSL 예제는 기존 `build.gradle.kts`와 병합이 필요하므로 자동
  수정하지 않습니다. bootstrap은 각 도구의 독립 규칙 파일만 복사합니다.

버전 자리표시자와 프로젝트 경로는 복사 후 반드시 소비 저장소에서 확정하고 전체 검증을
실행합니다.

bootstrap 자체의 회귀 검증은 다음 명령으로 실행합니다.

```sh
./scripts/test-bootstrap.sh
```

---

## 에이전트 연동 (AGENTS.md, CLAUDE.md, GEMINI.md)

agent 파일이 없으면 bootstrap이 다음 템플릿을 소비 저장소 루트에 생성합니다. 기존 파일이
있으면 프로젝트 지침을 보존하기 위해 자동 병합하지 않습니다.

`AGENTS.md`:
```markdown
# Repository Guidelines

## Shared Development Standards

Before modifying code, read `.dev-standards/styleguide.md`.
Repository-specific instructions in this file take precedence over the shared styleguide.
```

`CLAUDE.md`:
```markdown
@AGENTS.md
```

`GEMINI.md`:
```markdown
@./AGENTS.md
```

공유 표준 링크는 `AGENTS.md`에서만 관리합니다. `CLAUDE.md`와 `GEMINI.md`가
`AGENTS.md`를 다시 읽으므로 `styleguide.md`를 중복 참조하지 않습니다. 루트 `GEMINI.md`는
[Gemini CLI의 context import](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md)
진입점이고, `.gemini/styleguide.md`는 Gemini Code Assist에 동기화하는 병합 산출물입니다.
