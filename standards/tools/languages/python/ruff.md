# Ruff Guidelines

이 문서는 Python 프로젝트에서 Ruff를 lint와 format의 단일 진입점으로 사용하는 기준입니다.

## 설정과 버전

- Ruff 버전은 `mise.toml` 또는 프로젝트 dependency와 lockfile에 고정합니다.
- 저장소 루트의 `ruff.toml` 또는 기존 `pyproject.toml`의 `[tool.ruff]` 중 하나만
  설정 원본으로 사용합니다.
- `target-version`은 `pyproject.toml#requires-python` 및 mise의 Python 버전과 맞춥니다.
- 기본 규칙에 import 정렬(`I`), bugbear(`B`), Google docstring(`D`), pyupgrade(`UP`)와
  Ruff 전용 규칙(`RUF`)을 추가하되 기존 저장소에는 위반 현황을 확인한 뒤 단계적으로
  도입합니다.
- 시작점은 `templates/ruff/ruff.toml.example`이며 프로젝트 구조와 Python 버전에 맞게
  조정한 뒤 `ruff.toml`로 복사합니다.

## 실행과 예외

- CI에서는 `ruff check .`과 `ruff format --check .`을 모두 실행합니다.
- 자동 수정은 개발자가 `ruff check --fix .` 또는 `ruff format .`으로 명시적으로
  수행하고 diff를 검토합니다.
- `# noqa: <RULE>`은 구체적인 rule code와 불가피한 이유를 함께 남기며 file 전체
  예외보다 가장 작은 범위를 사용합니다.
- generated source와 외부 소유 코드는 source glob 또는 `exclude`로 분리합니다.

```sh
ruff check .
ruff format --check .
```

설정 형식은 [Ruff configuration](https://docs.astral.sh/ruff/configuration/)을 기준으로
합니다.
