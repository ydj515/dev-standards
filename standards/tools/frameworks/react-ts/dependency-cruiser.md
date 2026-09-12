# dependency-cruiser Guidelines

이 문서는 React + TypeScript 프로젝트에서 dependency-cruiser를 아키텍처 의존성 게이트로
사용하는 기준입니다. ESLint가 개별 파일의 코드 품질과 import 문법을 검사한다면,
dependency-cruiser는 전체 module graph의 계층 역전, 순환 의존과 해석 불가능한 import를
검사합니다.

## 선택 기준

- 단일 저장소의 React 애플리케이션과 package 수가 적은 workspace는 dependency-cruiser를
  기본 선택으로 사용합니다.
- 기존 ESLint 설정에서 디렉터리 유형별 import만 검사하면 충분한 경우에는
  `eslint-plugin-boundaries`를 대신 사용할 수 있습니다.
- Nx workspace는 별도 graph 도구를 추가하지 않고 `@nx/enforce-module-boundaries`와 project
  tag를 사용합니다.
- 같은 경계를 여러 도구에 중복 선언하지 않습니다. 한 도구를 아키텍처 규칙의 원본으로
  정하고 나머지는 순환 의존이나 public API처럼 겹치지 않는 책임만 맡깁니다.

## 설정과 경계

- dependency-cruiser를 exact devDependency와 lockfile에 고정합니다.
- 시작점은 `templates/dependency-cruiser/react-ts/.dependency-cruiser.cjs.example`입니다.
  bootstrap 이후 실제 `src/` 구조, alias와 application `tsconfig` 경로에 맞게 조정합니다.
- React의 기본 `feature-sliced` profile에서는
  `app → pages → widgets → features → entities → shared` 방향을 허용하고 하위 계층의 역방향
  import를 오류로 처리합니다.
- `stores`, `layouts`처럼 profile에 없는 root directory를 추가하면 어느 계층에 속하는지 먼저
  결정하고 같은 변경에서 rule과 정상·금지 fixture를 추가합니다.
- 순환 의존과 해석 불가능한 import는 CI 실패로 처리합니다. orphan 검사는 route entry,
  story와 test처럼 graph 진입점이 여러 개인 프로젝트에서 오탐 범위를 먼저 확인한 뒤
  활성화합니다.
- 예외는 rule을 비활성화하는 대신 최소 path와 제거 조건을 rule comment에 기록합니다.

## 실행과 검증

```json
{
  "scripts": {
    "imports:check": "depcruise src"
  }
}
```

```sh
pnpm exec depcruise src
```

CI에서는 lint와 typecheck 뒤, test와 build 전에 실행합니다. architecture profile 또는 source
root가 바뀌면 정상 import와 각 금지 방향을 나타내는 작은 fixture를 함께 갱신합니다.

참고: [dependency-cruiser rules](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md),
[ESLint Plugin Boundaries](https://www.jsboundaries.dev/docs/rules/),
[Nx module boundaries](https://nx.dev/docs/features/enforce-module-boundaries)
