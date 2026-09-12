# Tool Guide Organization

도구 문서는 도구가 주로 적용되는 언어 또는 프레임워크 아래에 둡니다.

```text
tools/
├─ languages/
│  ├─ go/golangci-lint.md
│  ├─ java/{checkstyle,pmd,spotbugs}.md
│  ├─ kotlin/detekt.md
│  ├─ python/{ruff,pyright}.md
│  └─ typescript/{eslint,prettier,biome,pnpm}.md
└─ frameworks/
   ├─ react-ts/{eslint-plugin-react-hooks,dependency-cruiser,vitest}.md
   └─ next-ts/eslint-config-next.md
```

- 한 도구 문서는 가장 직접적인 적용 범위 하나에 둡니다.
- 언어와 프레임워크 양쪽에서 사용되더라도 같은 내용을 복제하지 않고 주 소유 위치에서
  다른 가이드와의 조합을 설명합니다.
- 짧은 selector가 전체 `tools/**`에서 유일하면 `tools: [ruff]`처럼 선택합니다.
- 이름이 중복되면 `tools: [languages/python/ruff]`처럼 `tools/` 아래의 qualified path를
  사용합니다.
- qualified path의 각 segment와 파일명은 kebab-case를 사용합니다.
- framework 전용 도구는 `tools/frameworks/<framework>/`에 추가하고 해당 framework
  문서에서 책임과 적용 조건을 연결합니다.
- 여러 도구가 같은 설정 파일을 수정해야 하면 독립 bootstrap 템플릿을 중복 제공하지
  않습니다. 언어 도구의 설정을 기준으로 framework preset을 수동 병합하고 최종 파일은
  소비 저장소가 소유합니다.
