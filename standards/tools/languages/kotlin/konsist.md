# Konsist Guidelines

이 문서는 Kotlin source의 선언 규칙과 module/package architecture를 Konsist test로
검증하기 위한 기준입니다. Konsist는 Kotlin syntax와 declaration을 검사하며 formatter는
Spotless 또는 ktlint, 일반 정적 분석은 Detekt가 담당합니다.

## 의존성과 범위

- `com.lemonappdev:konsist` version을 test dependency와 version catalog에서 고정합니다.
- JUnit 또는 Kotest 중 저장소가 사용하는 test engine과 맞추고, Konsist test가 표준 `test`
  또는 별도 architecture test task에 실제 연결되는지 확인합니다.
- `scopeFromProject`, source set 또는 module 범위를 명시합니다. scope가 비어 있거나 일부
  module만 포함된 상태를 성공으로 처리하지 않습니다.

## Rule 설계

- package 배치, naming, declaration modifier와 layer dependency처럼 변경 영향이 큰 규칙부터
  추가합니다.
- `assertArchitecture`로 layer 간 허용 방향을 고정하고 예외는 최소 package/class에만
  허용합니다. 규칙의 적용 범위와 예외 제거 조건을 테스트에 남깁니다.
- 기존 부채를 숨기기 위한 광범위한 exclude와 빈 scope 허용을 기본값으로 사용하지 않습니다.
- Kotlin compiler, Konsist, test engine 버전의 호환성을 확인하고 정상·위반 fixture로
  규칙이 실제 실패하는지 검증합니다.

## 검증

```sh
./gradlew test --tests '*KonsistTest'
./gradlew check
```

참고: [Konsist getting started](https://docs.konsist.lemonappdev.com/getting-started/getting-started)
