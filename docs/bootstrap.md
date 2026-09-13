# 설정 Bootstrap과 Agent 연동

`bootstrap.sh`는 `.dev-standards/config.yml`에서 선택한 설정 템플릿과 agent 진입 파일을 소비
저장소에 최초 복사합니다. 애플리케이션 source나 framework directory는 생성하지 않습니다.

## 실행

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project
```

누락된 `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`만 생성하려면 `--agents-only`를 사용합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project \
  --agents-only
```

여러 mise profile 후보가 선택되면 하나를 명시해야 합니다.

```sh
./scripts/bootstrap.sh \
  --config /path/to/project/.dev-standards/config.yml \
  --target /path/to/project \
  --mise-profile typescript
```

지원 profile은 `gradle`, `maven`, `go`, `python`, `typescript`입니다.

## 생성 파일

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

Framework별 ESLint preset은 기존 `eslint.config.mjs`에 병합해야 하므로 별도 설정을 자동
복사하지 않습니다. mise bootstrap도 resolution 결과인 `mise.lock`을 만들지 않습니다.
자리표시자를 확정한 뒤 소비 저장소에서 `mise lock`을 실행합니다.

## 충돌과 소유권

- 대상 파일이 없으면 복사합니다.
- 대상 파일이 template과 같으면 변경 없이 성공합니다.
- 대상 파일이 이미 있고 내용이 다르면 어떤 파일도 복사하기 전에 실패합니다.
- 기존 agent 진입 파일은 덮어쓰거나 자동 병합하지 않고 경고 후 보존합니다.
- `--dry-run`은 파일을 변경하지 않고 복사 계획과 충돌을 검증합니다.
- React와 Spring source directory는 생성하지 않습니다.
- 기존 `build.gradle.kts`는 수정하지 않습니다. 품질 도구 Kotlin DSL 예시는 직접
  병합합니다.

Bootstrap은 최초 채택을 위한 seed입니다. 복사 이후 파일, version 자리표시자와 프로젝트
경로는 소비 저장소가 소유하고 검증합니다.

Checkstyle, PMD, SpotBugs, Detekt, ktlint, ArchUnit, Kover와 JaCoCo의 build 연결 예시는
`templates/gradle/<tool>/build.gradle.kts.example`에 있습니다. 이 파일들은 완성된 build를
대체하지 않으므로 bootstrap이 자동 복사하지 않습니다. 선택한 예시의 plugin, dependency,
task 설정만 기존 build에 병합합니다.

## Agent 진입 파일

참조 관계는 다음과 같습니다.

```text
CLAUDE.md ─┐
           ├─> AGENTS.md ─> .dev-standards/styleguide.md
GEMINI.md ─┘
```

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

공유 표준 링크는 `AGENTS.md`에서만 관리합니다. 기존 `AGENTS.md`가 있다면 위 section을 직접
병합합니다. 루트 `GEMINI.md`는 [Gemini CLI context import](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md)의
진입점이고, `.gemini/styleguide.md`는 Gemini Code Assist용 병합 산출물입니다.

Bootstrap 회귀 검증은 `./scripts/test-bootstrap.sh`로 실행합니다.
