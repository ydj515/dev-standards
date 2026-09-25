# 공통 공유 규칙 병합 Skill

`compose.sh`는 공유 규칙을 기존 agent 설정에 병합하는 skill을 함께 배포합니다.
스킬 이름은 모든 agent에서 `merge-dev-standards`입니다. 실행 중인 client와 관계없이
기본적으로 Codex, Claude Code, Gemini CLI 세 대상 모두를 처리합니다. 예를 들어 Claude에서
실행해도 `.agents/`, `.claude/`, `.gemini/`의 skill과 루트 진입 파일을 추가·병합합니다.
`AGENTS.md`를 공통 규칙의 SSOT로 두고 `CLAUDE.md`, `GEMINI.md`는 이를 참조합니다.
사용자가 "Gemini만"처럼 대상을 제한하면 해당 대상과 공통 의존 파일 `AGENTS.md`만
수정합니다. 기존에 `AGENTS.md`를 참조하는 다른 client에도 공통 규칙 변경이 적용됩니다.
`AGENTS.md`는 `.dev-standards/standards/`의 실제 원본 파일과 읽어야 할 조건을 안내합니다.
통합 `styleguide.md` 전체를 읽게 하지 않고 작업에 필요한 원본만 선택하게 합니다.

## 배포와 설치 경로

| Agent | 배포 경로 (`.dev-standards/` 기준) | 프로젝트 내 설치 경로 |
| --- | --- | --- |
| Codex | `codex/skills/merge-dev-standards/` | `.agents/skills/merge-dev-standards/` |
| Claude Code | `claude/skills/merge-dev-standards/` | `.claude/skills/merge-dev-standards/` |
| Gemini CLI | `gemini/skills/merge-dev-standards/` | `.gemini/skills/merge-dev-standards/` |

세 배포본은 다음 파일을 모두 포함하며 내용도 동일합니다. 원본은
`templates/agent-skills/`에서 한 번만 관리합니다.

```text
merge-dev-standards/
├── SKILL.md
├── assets/
│   ├── AGENTS.md
│   └── worktreeinclude
└── references/
    ├── merge-rules.md
    ├── codex.md
    ├── claude.md
    └── gemini.md
```

`SKILL.md`는 대상 선택과 절차 진입점이고, `merge-rules.md`는 보존·병합·검증 절차,
나머지 문서는 각 대상의 native 경로와 규칙 연결 방법입니다. 배포본 하나만으로도 세
대상을 모두 처리할 수 있으며, 다른 agent의 CLI를 실행하거나 설치할 필요가 없습니다.
Gemini가 같은 이름의 `.agents/skills/`를 우선 검색하더라도 동일한 기능을 제공합니다.
설치된 사본에 서로 다른 로컬 변경이 있다면 보존하고 검색 우선순위 문제를 보고합니다.

## 공식 Skill 포맷

세 agent 모두 `SKILL.md`의 YAML frontmatter에 `name`, `description`을 두고 본문은
Markdown으로 작성합니다. skill 디렉터리명과 `name`을 일치시키며, 상세 병합 절차는
본문에서 연결한 `references/merge-rules.md`를 필요할 때 읽습니다.

| Agent | 적용한 포맷과 호출 방식 |
| --- | --- |
| Codex | `SKILL.md` + `references/`; `$merge-dev-standards` 또는 description 기반 선택 |
| Claude Code | `SKILL.md` + `references/`; `/merge-dev-standards` 또는 description 기반 선택 |
| Gemini CLI | `SKILL.md` + `references/`; description 매칭 후 `activate_skill`로 활성화 |

Codex의 `agents/openai.yaml`은 선택적 UI·정책 메타데이터이므로 현재 instruction-only
skill에는 넣지 않습니다. Claude 전용 frontmatter인 `context`, `allowed-tools` 등의 추가
실행 설정도 필요하지 않아 생략하며, 이를 다른 agent에 복사하지 않습니다. Gemini CLI의
skill 활성화에는 CLI 자체의 동의 절차가 적용됩니다.

## 최초 실행과 갱신

배포 경로는 자동 검색 경로가 아닙니다. 최초 적용 시 agent에게 다음처럼 요청합니다.

```text
.dev-standards/claude/skills/merge-dev-standards/SKILL.md를 읽고,
이 프로젝트의 Codex, Claude, Gemini 규칙에 공유 표준을 병합하고 스킬도 설치해줘.
```

어느 agent의 배포 경로를 읽어도 실행 기능은 같습니다. 스킬이 native 경로에 설치된
뒤에는 Codex에서 `$merge-dev-standards`, Claude Code에서
`/merge-dev-standards`로 호출합니다. Gemini CLI는 `/skills reload` 후 공유 표준
적용을 요청합니다. Codex와 Claude도 설치 직후 검색되지 않으면 새 세션에서 확인합니다.

Claude Code에서 `/merge-dev-standards`는 세 대상을 모두 처리하며,
`/merge-dev-standards Gemini만`은 Gemini 대상만 처리합니다. 단순히 "Claude를 사용 중"이라고
말하는 것은 대상 제한으로 해석하지 않습니다.

## 적용 결과

| Agent | 규칙 진입점 | 공통 규칙 연결 |
| --- | --- | --- |
| Codex | 루트 `AGENTS.md` | `.dev-standards/standards/`의 작업별 원본 안내 |
| Claude Code | 루트 `CLAUDE.md` | `@AGENTS.md` |
| Gemini CLI | 루트 `GEMINI.md` | `@./AGENTS.md` |

전체 대상 실행 시 없는 `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`를 모두 생성합니다.
`AGENTS.md`에 공통 규칙을 병합하고 나머지 두 파일에는 참조만 추가합니다.

```text
프로젝트/
├── .dev-standards/             # styleguide, standards, 세 agent의 skill 배포본
├── .agents/skills/merge-dev-standards/
├── .claude/skills/merge-dev-standards/
├── .gemini/skills/merge-dev-standards/
├── .worktreeinclude            # 없으면 생성, 기존 패턴 보존
├── AGENTS.md                  # SSOT → standards/의 작업별 원본 안내
├── CLAUDE.md                  # @AGENTS.md
└── GEMINI.md                  # @./AGENTS.md
```

기존 Codex `AGENTS.override.md`가 있으면 로컬 지침을 보존하고 `AGENTS.md`를 읽도록
연결합니다. Gemini의 사용자 지정 context 파일이 있으면 루트 `GEMINI.md`도 유지하면서
실제 context 파일에서 `AGENTS.md`를 참조하도록 연결합니다. 설정 파일은 변경하지 않습니다.

배포본의 `assets/AGENTS.md`는 compose가 bootstrap 원본인
`templates/agents/AGENTS.md`에서 복사합니다. 별도 원본을 유지하지 않습니다.
새 문서는 이 템플릿의 여섯 H2와 설명을 유지하고, 기존 문서는 같은 의미의 섹션을
재사용하며 없는 섹션만 추가합니다. 원본 참조는 해당 섹션 아래에 병합합니다.
테스트 도구·커버리지 참조는 Testing Guidelines에 배치하고, 선택된 문서가 없어도
섹션 설명은 유지합니다. 기존 단일 표와 폴더 참조는 파일별 참조로 갱신하여 중복을 피합니다.

실제로 배포된 파일만 다음 기준으로 안내합니다.

| 작업 | 읽을 원본 (`.dev-standards/standards/` 기준) |
| --- | --- |
| 코드 수정 전 공통 규칙 | `base.md`가 있을 때 읽기 |
| 변경 작업 시작·브랜치 선택 | `workflows/branch.md` |
| 격리·병렬 작업, worktree 설정·정리 | `workflows/worktree.md` |
| 커밋 메시지 작성·수정 | `workflows/commit.md` |
| PR 제목·본문 작성·수정 | `workflows/pr.md` |
| 해당 언어 코드 수정 | `languages/`의 해당 언어 문서 |
| 모듈 구조·의존 방향 변경 | `architectures/`의 해당 모듈 아키텍처 문서 |
| 프레임워크 코드 수정 | `frameworks/`의 해당 프레임워크 문서 |
| 빌드·의존성 설정 변경 | `build-tools/`의 해당 빌드 도구 문서 |
| 도구 설정·해당 도구 작업 | `tools/`의 해당 문서 |
| 개발 런타임·환경 변경 | `runtime/`의 해당 문서 |

예를 들어 Java 코드 변경에는 `base.md`와 `languages/java.md`, Spring 코드라면
`frameworks/spring.md`도 읽도록 안내합니다. 관련 없는 언어·프레임워크는 읽지 않습니다.
스킬은 원본 파일 목록과 필요한 제목만 확인해 구체적인 파일 경로를 병합하고, 문서 본문은
복사하지 않습니다. 선택하지 않은 문서·빈 폴더·누락된 `base.md`는 안내에서 제외합니다.
원본이 없는 빈 `standards/`는 선택된 규칙이 없는 상태로 처리합니다.

commit·PR 가이드는 `base` 기본 선택에 포함되고 `base: false`이면 함께 제외됩니다.
branch·worktree 가이드도 같은 선택을 따릅니다.
커밋 가이드는 한국어 Conventional Commits 제목과 상세 항목 형식, PR 가이드는 한국어 제목과
요약·변경 사항·배경·테스트 결과·리뷰 포인트·참고 사항 형식을 정의합니다.
Conventional Commits의 타입·scope와 코드 식별자·파일명은 원문을 유지합니다.
두 가이드 모두 능동형 표현과 실제 변경 근거를 요구하며, PR 검증 결과는 실제 수행한
내용만 기록합니다. 스킬은 이 가이드들의 읽기 조건을 연결하며 직접 commit이나 PR을
생성하지 않습니다.

루트 `.worktreeinclude`는 `assets/worktreeinclude`에서 파일이 없을 때만 생성합니다.
기존 파일은 주석·패턴까지 그대로 보존하며 자동으로 환경 파일 경로를 추가하지 않습니다.
템플릿은 복사 대상이 없는 주석만 포함합니다. 선택 대상을 제한해도 이 공통 설정을
확인하며, `base: false`와 관계없이 생성할 수 있습니다. 이 단계는 worktree 생성이나
로컬 파일 복사를 실행하지 않습니다. 실제 복사 지원 범위는 worktree 가이드를 참고합니다.

스킬은 없는 디렉터리·문서를 생성하고 기존 문서에는 공유 규칙 참조를 병합합니다.
`AGENTS.md`는 H2별로 참조를 갱신하고 단일 관리 표를 새로 추가하지 않습니다.
기존 관리 구간에서는 공유 참조만 해당 섹션으로 옮기고 로컬 설명을 보존합니다.
다른 agent 진입 파일에서는 `dev-standards:begin/end` 구간 또는 기존 참조를 재사용합니다.
프로젝트 고유 규칙과 frontmatter, 다른 skills, hooks, 설정 및 권한은 보존합니다.
충돌하거나 marker가 손상된 파일은 덮어쓰지 않고 보고합니다. symlink 대상은 수정하지
않습니다. 설치된 skill에 로컬 변경이 있으면 배포본과 비교해 보존하며 병합합니다.

`.codex/dev-standards.md`, `.claude/rules/dev-standards.md`, `.gemini/dev-standards.md`는
새로 생성하지 않습니다. 이전에 생성된 파일이 있다면 삭제하지 않고, 선택된 대상의 명확한
관리 구간만 `AGENTS.md` 참조로 전환합니다. 로컬 규칙과 불명확한 중복은 보존·보고하며
순환 참조가 생기지 않는지 확인합니다.

Compose/CI는 배포본만 갱신하고, 실제 설정 병합은 skill을 실행할 때 수행합니다.
기존 bootstrap의 진입 파일 생성·보존 동작은 유지됩니다. 따라서 skill 절차가 변경되면
설치된 skill을 다시 실행해 현재 배포본과 병합합니다. 원본 내용만 바뀌면 기존 경로로 최신
규칙을 읽습니다. 선택 모듈이 추가·제거되면 스킬을 다시 실행해 파일 목록을 갱신합니다.
목록 갱신 전에도 해당 분류의 실제 파일을 확인하도록 안내합니다. 이전의 styleguide 전체
읽기 지침은 소유권이 명확한 관리 구간에서 이 안내로 교체합니다.

`styleguide.md` 생성과 Gemini Code Assist용 병합본은 기존 호환성을 위해 유지합니다.
bootstrap은 작업별 폴더 안내를 생성하며, 스킬은 이를 실제 파일별 안내로 구체화합니다.

이전 `apply-dev-standards-*` 이름의 skill이 이미 설치되어 있다면 자동 삭제하지 않고
기존 이름이 남아 있음을 보고합니다. 새 호출 이름은 `merge-dev-standards`입니다.

## 공식 경로 근거

- [Codex skill 검색 경로](https://learn.chatgpt.com/docs/build-skills): 프로젝트 `.agents/skills/`.
- [Claude Code skills](https://code.claude.com/docs/ko/skills)와
  [project rules](https://code.claude.com/docs/en/memory): `.claude/skills/`, `.claude/rules/`.
- [Gemini CLI skills](https://geminicli.com/docs/cli/skills/)와
  [context import](https://geminicli.com/docs/cli/gemini-md/): `.gemini/skills/`, `GEMINI.md`.

Gemini Code Assist용 `.gemini/styleguide.md`는 기존 CI 옵션의 별도 산출물입니다.
