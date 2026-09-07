# Biome Guidelines

이 문서는 TypeScript 프로젝트에서 Biome를 formatter, linter와 import 정렬의 단일
도구로 사용하는 기준입니다.

- `@biomejs/biome`은 exact devDependency와 lockfile로 버전을 고정합니다. patch release도
  출력 차이를 만들 수 있으므로 floating range를 사용하지 않습니다.
- 저장소 루트의 `biome.json`을 설정 원본으로 사용하고 Git ignore 파일을 존중합니다.
- `formatter`, recommended `linter`, `assist/source/organizeImports`를 같은 설정에서
  관리합니다.
- 시작점은 `templates/biome/biome.json.example`이며 설치된 package의 schema를 참조합니다.
- CI는 파일을 수정하지 않는 `biome ci .`를 사용하고, 로컬 자동 수정은
  `biome check --write .`로 분리합니다.
- Prettier와 동시에 선택하지 않습니다. ESLint와 함께 사용할 때는 중복되는 lint 책임을
  어느 도구가 소유하는지 명시하고 한쪽 규칙을 비활성화합니다.

```sh
pnpm exec biome ci .
pnpm exec biome check --write .
```

설정과 명령은 [Biome configuration](https://biomejs.dev/reference/configuration/)과
[Biome CLI](https://biomejs.dev/reference/cli/)를 기준으로 합니다.
