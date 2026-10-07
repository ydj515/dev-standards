# Spotless Guidelines

이 문서는 Java와 Kotlin/JVM source의 formatting을 Spotless로 일관되게 적용하기 위한
기준입니다. Spotless는 formatting을 담당하며 architecture, bug pattern과 dependency
검증은 Checkstyle, Detekt, ArchUnit 또는 Konsist에 맡깁니다.

## 선택과 설정

- `tools: [spotless]`로 명시적으로 선택합니다. `languages: [java]` 또는
  `languages: [kotlin]`만 선택해도 Spotless를 자동 추가하지 않습니다.
- Gradle plugin `com.diffplug.spotless` 버전을 version catalog와 lock 정책으로 고정합니다.
- Java는 `googleJavaFormat`, `palantirJavaFormat` 또는 저장소가 선택한 formatter 하나를
  고정하고, Kotlin은 `ktfmt` 또는 `ktlint` 중 Spotless가 호출할 formatter의 소유권을
  명확히 합니다. 같은 파일을 두 formatter가 수정하지 않게 합니다.
- `.editorconfig`와 formatter 설정의 우선순위를 기록하고 generated source는 실제 경로만
  제외합니다. `build/`, 외부 소유 코드와 캐시는 포맷 대상에 포함하지 않습니다.
- 기존 코드 전체를 한 번에 재포맷하지 않으려면 `ratchetFrom` 기준을 지정하고 별도 포맷
  커밋과 기능 변경을 분리합니다.

## 검증

CI에서는 파일을 수정하지 않는 `spotlessCheck`만 실행하고, 개발자가 명시적으로
`spotlessApply`를 실행합니다.

```sh
./gradlew spotlessCheck
./gradlew spotlessApply
```

`spotlessCheck`를 root `check` 또는 프로젝트의 표준 검증 task에 연결하고, 적용한 formatter와
대상 source set을 문서에 기록합니다.

참고: [Spotless Gradle plugin](https://github.com/diffplug/spotless/tree/main/plugin-gradle)
