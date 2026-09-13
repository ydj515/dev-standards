# 선택 설정

소비 저장소는 `.dev-standards/config.yml`에서 적용할 표준 모듈을 선택합니다. 설정 원본,
생성된 styleguide와 개별 표준은 `.dev-standards/` namespace 아래에서 관리합니다.

## 설정 형식

```yaml
version: 1
base: true
languages:
  - kotlin
  - typescript
architectures:
  - domain-oriented
frameworks:
  - spring
builds:
  - gradle
tools:
  - detekt
  - checkstyle
runtimes:
  - mise
```

| 필드 | 설명 |
| --- | --- |
| `version` | 설정 schema 버전 |
| `base` | 공통 개발 원칙 포함 여부. 생략하면 `true` |
| `languages` | 언어별 타입, 오류 처리와 생태계 관용구 |
| `architectures` | package 구조와 의존 방향 profile |
| `frameworks` | framework 실행 모델과 구조 적용 기준 |
| `builds` | Gradle, Maven 같은 build tool 기준 |
| `tools` | lint, format, typecheck, architecture와 coverage 도구 기준 |
| `runtimes` | mise 같은 개발 runtime 기준 |

배열은 block 또는 inline 형식을 지원하며 선언 순서대로 조합합니다. `architectures` 이외의
배열은 생략하거나 `[]`로 두면 해당 계층을 조합하지 않습니다.

## Architecture 선택

언어만으로 애플리케이션 구조를 추론하지 않습니다. `architectures`를 생략했을 때만 선택한
framework에 따라 다음 기본값을 적용합니다.

| Framework | 기본 architecture | 의존 방향 |
| --- | --- | --- |
| `spring` | `layered-clean` | `presentation → application → domain ← infrastructure` |
| `fastapi` | `feature-layered` | 기능 package 내부의 HTTP/application/domain/adapter 분리 |
| `react-ts` | `feature-sliced` | `app → pages → widgets → features → entities → shared` |
| `next-ts` | `route-feature` | App Router 경계와 server/client feature 분리 |

- `architectures: []`는 framework 기본값을 비활성화합니다.
- 하나 이상 명시하면 framework 기본값을 대체합니다.
- `react-ts`와 `next-ts`를 함께 선택하면 더 구체적인 `route-feature`를 적용합니다.
- Bootstrap, MUI, Tailwind와 Thymeleaf는 상위 애플리케이션 구조를 바꾸지 않습니다.
- 작은 프로젝트는 논리적 경계를 유지하는 범위에서 물리적인 file과 package를 합칠 수
  있습니다.

Spring에 bounded context 우선 구조를 적용하는 예:

```yaml
version: 1
languages: [kotlin]
frameworks: [spring]
architectures: [domain-oriented]
```

Spring을 사용하지만 architecture profile을 적용하지 않는 예:

```yaml
version: 1
languages: [kotlin]
frameworks: [spring]
architectures: []
```

언어만 선택한 Go 서비스에서 domain-oriented 구조를 사용하는 예:

```yaml
version: 1
languages: [go]
architectures: [domain-oriented]
```

## Tool selector

도구 문서는 `standards/tools/languages/<language>/` 또는
`standards/tools/frameworks/<framework>/`에 둡니다. 이름이 전체 도구 트리에서 유일하면
`ruff`처럼 짧게 선택하고, 중복되면 `languages/python/ruff`처럼 qualified selector를
사용합니다.

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

- TypeScript formatter는 Prettier 또는 Biome 중 하나만 선택합니다.
- Next.js는 `frameworks/next-ts/eslint-config-next`를 선택하고 일반 TypeScript 규칙과 같은
  `eslint.config.mjs`에서 병합합니다.
- Python의 기본 품질 조합은 `tools: [ruff, pyright]`입니다.
- 전체 selector 목록은 [도구 표준](../standards/tools/README.md)을 참고합니다.

## 생태계별 품질 책임

Java/Kotlin과 React/TypeScript 도구는 다음 책임으로 대응합니다. 내부 분석 방식이 같다는
의미가 아니라 CI에서 같은 실패 범위를 담당한다는 의미입니다.

| Java/Kotlin 생태계 | React / TypeScript 대응 | 역할 |
| --- | --- | --- |
| Detekt / PMD | ESLint | 정적 분석, 코드 품질, 버그 패턴 탐지 |
| Checkstyle / ktlint | ESLint + Prettier | 코딩 컨벤션 + 포맷팅 |
| ArchUnit | dependency-cruiser / eslint-plugin-boundaries / Nx module boundaries | 아키텍처/레이어 의존성 검증 |
| SpotBugs | ESLint + TypeScript compiler | 잠재 버그/타입 오류 |
| JaCoCo | Vitest/Jest + V8/Istanbul coverage | 테스트 커버리지 |
