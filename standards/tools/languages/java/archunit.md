# ArchUnit Guidelines

이 문서는 Java와 Kotlin/JVM 프로젝트의 package, layer와 dependency 방향을 ArchUnit test로
검증하기 위한 기준입니다. ArchUnit은 compile된 JVM bytecode를 분석하므로 framework 문서의
의존 규칙을 실행 가능한 test로 고정하는 데 사용합니다.

## 의존성과 실행

- JUnit 5 프로젝트는 `com.tngtech.archunit:archunit-junit5` version을 test dependency로
  고정합니다.
- Gradle Kotlin DSL 시작점은 `templates/gradle/archunit/build.gradle.kts.example`입니다.
- architecture test 이름과 Gradle filter를 일치시키고 root `check` 또는 프로젝트 `verify`가
  반드시 실행하게 합니다.
- production class만 import하고 test fixture, generated class와 third-party package는 분석
  범위에서 제외합니다.

## Rule 설계

- package 이름이 아니라 실제 architecture profile의 dependency 방향을 먼저 정의합니다.
- layer access, domain의 framework 독립성, transaction annotation 소유 위치와 slice cycle처럼
  변경 시 영향이 큰 규칙부터 추가합니다.
- class suffix, 모든 public method와 같은 구현 세부를 과도하게 고정하지 않습니다.
- 예외는 전체 rule을 비활성화하지 않고 최소 package/class만 허용하며 기술적 이유와 제거
  조건을 기록합니다.
- `allowEmptyShould(true)`로 package 오타나 빈 분석 범위를 숨기지 않습니다.

## Java와 Kotlin

JUnit integration의 `@AnalyzeClasses`와 `@ArchTest`를 사용하면 imported class cache와 test
실행을 재사용할 수 있습니다. Kotlin source도 JVM bytecode로 분석되지만 top-level declaration,
companion object와 synthetic class 이름에 직접 결합하는 규칙은 피합니다.

architecture profile이 바뀌면 정상 dependency와 각 금지 방향을 나타내는 작은 fixture를
같은 변경에서 갱신합니다.

## 검증

```sh
./gradlew architectureTest
./gradlew check
```

```sh
./mvnw test
./mvnw verify
```

참고: [ArchUnit User Guide](https://www.archunit.org/userguide/html/000_Index.html)
