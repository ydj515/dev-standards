# SpotBugs Guidelines

이 문서는 compile된 Java bytecode에서 bug pattern을 찾는 SpotBugs를 재현 가능한 품질
게이트로 운영하기 위한 기준입니다. SpotBugs 결과는 결함 후보이며 테스트와 domain
검증을 대체하지 않습니다.

## 분석 계약

- SpotBugs engine과 build plugin 버전을 프로젝트가 고정합니다.
- production class와 test class의 분석 여부를 명시하고 필요한 compile task 이후에
  실행합니다.
- `ignoreFailures`, `failOnError`, 허용 위반 수 설정으로 새 finding을 성공 처리하지
  않습니다.
- effort와 confidence 수준을 변경할 때는 실행 시간과 finding 변화를 측정합니다.
- 공통 filter 경로는 `config/spotbugs/exclude-filter.xml`로 두고 Gradle과 Maven에서
  같은 예외 계약을 사용합니다.
- 시작점은 `templates/spotbugs/exclude-filter.xml`을 사용하고 실제 예외가 생길 때만
  좁은 `Match`를 추가합니다.

## Gradle 연결

- `com.github.spotbugs` plugin 버전을 고정하고 `spotbugsMain`, `spotbugsTest` task를
  필요한 source set에 적용합니다.
- Kotlin DSL 시작점은 `templates/gradle/spotbugs/build.gradle.kts.example`을 사용하고
  plugin과 engine 버전을 각각 고정합니다.
- `runOnCheck` 또는 명시적 dependency로 전체 `check`에서 분석이 실행되게 합니다.
- report format과 저장 경로를 CI artifact 및 review 도구가 읽을 수 있게 고정합니다.
- exclude filter와 baseline 파일을 사용할 때는 경로와 갱신 절차를 저장소에 기록합니다.

## Maven 연결

- `com.github.spotbugs:spotbugs-maven-plugin` 버전을 POM에서 고정합니다.
- analysis와 violation 검증이 `verify` lifecycle에서 모두 실행되는지 goal 계약을
  확인합니다.
- `failOnError`를 유지하고 test class 분석 여부를 명시합니다.
- multi-module aggregate report는 module별 gate를 대체하지 않게 구성합니다.

## finding 처리와 검증

- finding의 source 경로와 bytecode 위치를 실제 코드에서 확인한 뒤 수정 또는 예외
  처리합니다.
- annotation으로 억제할 때는 정확한 bug pattern과 근거를 기록합니다.
- 생성 코드나 외부 소유 class만 filter로 제외하고 package 전체를 편의상 제외하지
  않습니다.

```sh
./gradlew spotbugsMain spotbugsTest
./gradlew check
```

```sh
./mvnw spotbugs:check
./mvnw verify
```
