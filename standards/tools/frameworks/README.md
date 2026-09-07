# Framework Tool Guides

프레임워크 전용 분석기, 플러그인 또는 검증 도구는
`standards/tools/frameworks/<framework>/<tool>.md`에 둡니다.

- 언어 자체에 적용되는 도구는 `standards/tools/languages/`에 둡니다.
- 프레임워크를 사용하지 않으면 의미가 없는 규칙만 이 계층에 둡니다.
- 공통 설정을 복제하지 않고 언어 도구와 함께 선택하는 방법을 문서화합니다.
- 같은 파일명의 도구가 다른 범위에도 있으면
  `frameworks/<framework>/<tool>` qualified selector를 사용합니다.

현재 등록된 프레임워크 전용 도구는 다음과 같습니다.

- `frameworks/react-ts/eslint-plugin-react-hooks`: React Hook과 render 규칙
- `frameworks/next-ts/eslint-config-next`: Next.js, React와 Core Web Vitals ESLint 규칙

두 도구 모두 기존 `eslint.config.mjs`에 병합하는 설정이므로 독립 bootstrap 템플릿을
두지 않습니다. 같은 target file을 자동 합성하지 않고 소비 저장소가 최종 config와 package
버전을 소유합니다.
