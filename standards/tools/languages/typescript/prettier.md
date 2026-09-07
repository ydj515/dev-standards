# Prettier Guidelines

이 문서는 TypeScript 프로젝트에서 Prettier를 formatter로 사용하는 기준입니다.

- Prettier는 `package.json`의 exact devDependency와 lockfile로 버전을 고정합니다.
- 저장소 루트의 `prettier.config.mjs`를 설정 원본으로 사용하고 전역 설정에 의존하지
  않습니다.
- lint는 ESLint, format은 Prettier로 역할을 분리하며 style rule을 두 도구에 중복
  선언하지 않습니다.
- `templates/prettier/prettier.config.mjs.example`과 `.prettierignore.example`을 복사한 뒤
  generated output 경로를 프로젝트에 맞게 조정합니다.
- CI는 `prettier . --check`, 개발자 수정 명령은 `prettier . --write`로 분리합니다.
- Biome과 동시에 선택하지 않습니다. Biome으로 전환할 때는 설정을 먼저 변환하고 결과
  diff를 검토한 뒤 Prettier dependency와 설정을 제거합니다.

```sh
pnpm exec prettier . --check
pnpm exec prettier . --write
```

설정 형식은 [Prettier configuration](https://prettier.io/docs/configuration)을 기준으로
합니다.
