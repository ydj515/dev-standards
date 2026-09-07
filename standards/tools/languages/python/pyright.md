# Pyright Guidelines

이 문서는 Python 프로젝트에서 Pyright를 재현 가능한 정적 타입 검사로 사용하는 기준입니다.

## 설정과 버전

- 공식 CLI인 npm `pyright` 버전과 이를 실행하는 Node.js 버전을 함께 고정합니다.
- 저장소 루트의 `pyrightconfig.json` 또는 `pyproject.toml#tool.pyright` 중 하나만
  설정 원본으로 사용합니다. 두 파일이 함께 있으면 `pyrightconfig.json`이 우선합니다.
- `pythonVersion`은 지원하는 최소 Python 버전과 일치시키고, uv를 사용하면 프로젝트의
  `.venv`를 명시적으로 연결합니다.
- 신규 프로젝트는 `strict`에서 시작합니다. 기존 프로젝트는 `basic`에서 오류 수를
  측정하고 module 단위로 strict 범위를 확대할 수 있습니다.
- 시작점은 `templates/pyright/pyrightconfig.json.example`이며 source와 test 경로를
  실제 layout에 맞게 조정합니다.

## 실행과 예외

- `pyright`를 CI와 `mise run verify`에 포함하고 IDE 진단과 동일한 설정 파일을 사용합니다.
- `# type: ignore`는 구체적인 진단 rule과 이유를 기록하고 외부 library의 type stub 문제는
  가능한 경우 stub package 또는 local stub으로 해결합니다.
- type check 성공은 runtime validation을 대체하지 않습니다.

```sh
pyright
```

설정과 CLI는 [Pyright configuration](https://github.com/microsoft/pyright/blob/main/docs/configuration.md)과
[공식 설치 안내](https://github.com/microsoft/pyright/blob/main/docs/installation.md)를 기준으로
합니다.
