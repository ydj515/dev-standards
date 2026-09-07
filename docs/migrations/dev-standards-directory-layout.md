# Development Standards Directory Layout Migration

이 문서는 기존 루트 설정과 단일 `guide.md`를 사용하는 소비 저장소를
`.dev-standards/` namespace 기반 구조로 전환하는 절차입니다.

## 변경 요약

기존 구조:

```text
consumer-repository/
├─ .dev-standards.yml
└─ .dev-standards/
   └─ guide.md
```

새 구조:

```text
consumer-repository/
└─ .dev-standards/
   ├─ config.yml
   ├─ styleguide.md
   └─ standards/
      ├─ base.md
      ├─ languages/
      ├─ architectures/
      ├─ frameworks/
      ├─ build-tools/
      ├─ tools/
      └─ runtime/
```

- `config.yml`은 소비 저장소가 작성하고 소유합니다.
- `styleguide.md`는 선택된 문서를 합친 단일 AI 도구 진입점입니다.
- `standards/**`는 같은 선택 결과를 원본 계층대로 복사한 생성물입니다.
- `.gemini/styleguide.md`를 사용하는 경우 병합본과 같은 내용으로 유지됩니다.
- React와 Spring의 소스 및 package 디렉터리는 이 마이그레이션에서 변경하지 않습니다.

## 사전 확인

1. 소비 저장소에 미완료 변경이 있는지 확인합니다.

   ```sh
   git status --short
   ```

2. 현재 `.dev-standards.yml`, `.dev-standards/guide.md`, 호출 workflow와 에이전트 지침
   파일의 위치를 확인합니다.

   ```sh
   git ls-files \
     .dev-standards.yml \
     .dev-standards/guide.md \
     '.github/workflows/*.yml' \
     AGENTS.md \
     CLAUDE.md \
     GEMINI.md
   ```

3. 소비 저장소가 참조하는 `ci-workflows`와 `dev-standards` ref를 기록합니다. 운영
   저장소는 변경 가능한 branch보다 검증된 tag 또는 commit SHA를 사용하는 것을 권장합니다.

## 마이그레이션 절차

### 1. 설정 파일 이동

`.dev-standards/`가 없으면 만든 뒤 설정 파일을 이동합니다.

```sh
mkdir -p .dev-standards
git mv .dev-standards.yml .dev-standards/config.yml
```

설정 내용과 `base`, `languages`, `frameworks`, `builds`, `tools`, `runtimes` 선택은 그대로
유지합니다. `architectures`를 생략하면 선택한 프레임워크의 기본 profile이 새로
포함되며, 언어만으로는 architecture를 추론하지 않습니다. Go에 `domain-oriented`를
적용하려면 `architectures: [domain-oriented]`를 명시합니다. 프레임워크 기본값도 원하지
않으면 `architectures: []`를 추가합니다. 단수형 호환 키를 사용 중이라면 이때 복수형
키로 정리합니다.

### 2. 호출 workflow 수정

설정 변경을 감지하는 경로를 새 위치로 변경합니다.

```yaml
on:
  workflow_dispatch:
  push:
    paths:
      - ".dev-standards/config.yml"
```

새 reusable workflow의 기본 `config_path`가 `.dev-standards/config.yml`이므로 별도 지정은
필요하지 않습니다.

```yaml
jobs:
  sync:
    uses: your-org/ci-workflows/.github/workflows/sync-dev-standards.yml@REPLACE_WITH_CI_WORKFLOWS_REF
    with:
      standards_owner: your-org
      standards_repo: dev-standards
      standards_ref: REPLACE_WITH_DEV_STANDARDS_REF
```

아직 설정 파일을 이동할 수 없는 저장소만 전환 기간에 기존 경로를 명시합니다.

```yaml
with:
  standards_owner: your-org
  config_path: .dev-standards.yml
```

이 호환 설정은 입력 경로만 유지합니다. 새 workflow의 산출물은 항상
`.dev-standards/styleguide.md`와 `.dev-standards/standards/**`입니다.

### 3. 에이전트 지침 링크 수정

`AGENTS.md`에서 이전 `guide.md` 링크를 병합된 `styleguide.md`로 변경합니다.

```markdown
## Shared Development Standards

Before modifying code, read `.dev-standards/styleguide.md`.
Repository-specific instructions in this file take precedence over the shared styleguide.
```

`CLAUDE.md`는 병합본을 중복 참조하지 않고 `AGENTS.md`만 참조합니다.

```markdown
@AGENTS.md
```

`GEMINI.md`도 Gemini CLI의 상대 import 문법으로 `AGENTS.md`만 참조합니다.

```markdown
@./AGENTS.md
```

파일이 없으면 bootstrap으로 만들 수 있습니다. 이미 있으면 bootstrap이 보존하므로 기존
프로젝트 지침을 유지한 채 위 import를 직접 병합합니다.

개별 규칙을 직접 검토하거나 특정 영역만 참조해야 할 때는
`.dev-standards/standards/**`를 사용합니다.

### 4. 첫 동기화 실행

수정한 호출 workflow를 `workflow_dispatch`로 한 번 실행합니다. 첫 실행은 다음 작업을
하나의 동기화 변경으로 만듭니다.

- `.dev-standards/styleguide.md` 생성
- 선택된 `.dev-standards/standards/**` 생성
- 기존 `.dev-standards/guide.md` 삭제
- `sync_gemini`이 활성화된 경우 `.gemini/styleguide.md` 갱신

`bootstrap_templates`는 이 경로 마이그레이션에 필요하지 않습니다. 기존 프로젝트 설정을
유지하려면 비활성화된 기본값을 사용합니다. 실제 설정 파일을 최초 채택하는 별도 작업에서만
활성화합니다.

## 검증

첫 동기화가 완료되면 다음을 확인합니다.

```sh
test -f .dev-standards/config.yml
test -f .dev-standards/styleguide.md
test -d .dev-standards/standards
test ! -e .dev-standards/guide.md
```

Gemini 동기화를 사용하는 저장소는 두 병합본이 같은지도 확인합니다.

```sh
cmp .dev-standards/styleguide.md .gemini/styleguide.md
```

선택 결과와 개별 파일을 확인합니다.

```sh
find .dev-standards/standards -type f | sort
git diff --check
git status --short
```

검증할 때 다음 계약을 함께 확인합니다.

- `styleguide.md`에 `config.yml`에서 선택한 모든 표준이 선언 순서대로 포함되어 있습니다.
- `standards/**`에는 같은 선택만 존재하며 이전 선택에서 제거된 stale 문서가 없습니다.
- `.dev-standards/config.yml`은 workflow가 수정하지 않았습니다.
- React/Spring 애플리케이션 소스 구조와 프로젝트 소유 설정 파일은 변경되지 않았습니다.

## 실패 처리와 롤백

- 새 설정 경로를 찾지 못하면 호출 workflow의 trigger 경로와 `config_path`를 확인합니다.
- `styleguide.md`는 생성됐지만 개별 파일이 없으면 `--modules-dir`을 지원하는
  `dev-standards` ref와 새 `ci-workflows` ref가 함께 사용됐는지 확인합니다.
- bootstrap 충돌은 마이그레이션 실패가 아닙니다. 경로 이동 작업에서는
  `bootstrap_templates`를 끄고 기존 프로젝트 설정을 보존합니다.
- 전체 산출물 구조를 되돌려야 하면 설정 파일만 다시 옮기지 말고, 이전 동작이 고정된
  `ci-workflows`와 `dev-standards` tag 또는 commit SHA를 함께 복원합니다.

롤백 후에도 새 workflow가 만든 파일은 자동으로 삭제되지 않을 수 있으므로 실제 diff를
확인하고 생성물만 별도 정리합니다. 애플리케이션 소스와 bootstrap으로 프로젝트가 소유하게
된 설정 파일은 롤백 정리 대상에 포함하지 않습니다.

## 주의사항

- 제약: 하나의 workflow 호출은 하나의 `config_path`와 저장소 루트 산출물 집합을 관리합니다.
- 위험: `AGENTS.md`가 삭제된 `guide.md`를 계속 참조하거나 `CLAUDE.md` 또는 `GEMINI.md`가
  `AGENTS.md`를 참조하지 않으면 에이전트가 표준을 읽지 못합니다.
- 예외: 기존 루트 `.dev-standards.yml`은 명시적인 `config_path`로 읽을 수 있지만 산출물
  이름과 위치는 이전 방식으로 돌아가지 않습니다.
