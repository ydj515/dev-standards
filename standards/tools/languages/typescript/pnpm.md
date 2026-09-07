# pnpm Guidelines

이 문서는 Node.js와 TypeScript 프로젝트에서 pnpm을 재현 가능한 package manager로
사용하는 기준입니다.

- pnpm 버전은 `package.json#packageManager`와 `mise.toml`에 같은 exact version으로
  고정하고 lockfile과 함께 변경합니다.
- CI는 `pnpm install --frozen-lockfile`을 사용해 lockfile 변경이나 dependency 재해석을
  허용하지 않습니다.
- pnpm 12 기준 프로젝트 설정은 단일 패키지여도 `pnpm-workspace.yaml`에 둡니다.
  시작점은 `templates/pnpm/pnpm-workspace.yaml.example`이며 단일 패키지는 `packages`
  항목만 제거합니다.
- 새 dependency를 exact version으로 기록하도록 `savePrefix: ""`를 사용하고, Node engine과
  peer dependency 불일치를 각각 `engineStrict`, `strictPeerDependencies`로 실패시킵니다.
- `.npmrc`에는 registry와 인증 설정만 둡니다. 인증 token은 파일에 직접 기록하지 않고
  CI secret이나 승인된 secret manager에서 환경변수로 주입합니다.
- dependency 추가와 upgrade는 `pnpm add` 또는 `pnpm update`로 명시적으로 수행하고
  `package.json`과 `pnpm-lock.yaml`을 함께 검토합니다.
- lifecycle script 실행 정책과 registry 인증은 프로젝트 보안 정책에 맞게 별도로
  관리하며 token을 `.npmrc`에 기록하지 않습니다.

```json
{
  "packageManager": "pnpm@REPLACE_ME"
}
```

```sh
pnpm install --frozen-lockfile
pnpm run verify
```

pnpm 설정과 설치 동작은 [pnpm settings](https://pnpm.io/settings)와
[pnpm install](https://pnpm.io/cli/install)을 기준으로 합니다. pnpm 11 이하를 유지하는
프로젝트는 고정한 major 버전의 문서에 맞춰 설정 위치를 확인합니다.
