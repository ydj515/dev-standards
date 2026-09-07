# Maven Build Guidelines

이 문서는 Maven 프로젝트의 빌드 재현성, dependency와 plugin 버전 관리, lifecycle 기반
검증을 일관되게 운영하기 위한 기준입니다. 실제 Maven, plugin, dependency 버전은 각
프로젝트가 호환성을 확인한 뒤 고정합니다.

## Maven Wrapper

- 시스템에 설치된 `mvn` 대신 저장소의 `./mvnw` 또는 `mvnw.cmd`를 사용합니다.
- Wrapper script와 `.mvn/wrapper/` 설정을 함께 버전 관리해 개발자와 CI가 같은 Maven
  버전을 사용하게 합니다.
- Wrapper를 변경할 때는 distribution URL과 내려받기 방식을 함께 검토합니다.
- `.mvn/wrapper/maven-wrapper.properties`에 `distributionSha256Sum`을 기록합니다. Wrapper
  JAR를 내려받는 유형이면 `wrapperSha256Sum`도 기록하고 두 값의 변경을 별도로 검토합니다.
- `pom.xml`, `.mvn/` 확장과 Wrapper는 실행에 영향을 주므로 신뢰하지 않는 변경을
  검토 없이 실행하지 않습니다.

## POM 버전 관리

- Java release, 문자 인코딩, dependency와 build plugin 버전은 `<properties>`에서
  의미 있는 이름으로 중앙화합니다.
- 여러 module에서 공유하는 dependency 버전은 parent POM의 `<dependencyManagement>`
  또는 검증된 BOM import로 관리합니다.
- `<dependencyManagement>`는 실제 dependency를 추가하지 않으므로 사용하는 module의
  `<dependencies>`에는 직접 선언합니다.
- plugin 버전과 공통 설정은 `<pluginManagement>`에서 관리합니다.
- `<pluginManagement>`만으로 plugin이 실행되지는 않으므로 lifecycle에 기본 연결되지
  않은 plugin은 `<build><plugins>`에 명시하고 execution phase를 지정합니다.
- Super POM이나 실행 환경의 암묵적 기본값에 의존하지 않도록 중요한 build plugin
  버전을 고정합니다.
- dependency version range는 resolution 결과가 시점에 따라 바뀔 수 있으므로 사용하지
  않습니다. release와 필수 CI 경로에서는 mutable `SNAPSHOT` dependency를 허용하지 않습니다.
- 배포 artifact의 archive timestamp를 고정할 수 있도록 `project.build.outputTimestamp`를
  release 절차가 관리하고, 재현 가능한 버전의 build plugin을 사용합니다.

최소 구조는 `templates/maven/pom.xml.example`을 참고하되, 모든 `REPLACE_ME` 자리표시자는
프로젝트가 검증한 값으로 교체합니다.

## Multi-module 구조

- aggregator root는 `packaging`을 `pom`으로 두고 module 목록과 공통 관리를 소유합니다.
- 공통 parent 설정과 배포용 BOM의 책임이 커지면 별도 artifact로 분리합니다.
- module별 dependency는 실제 사용하는 module에 선언하고 root POM에 무조건 올리지
  않습니다.
- profile은 환경 차이를 숨기는 기본 수단으로 사용하지 않고, 활성화 조건과 CI 적용
  여부를 문서화합니다.

## 검증과 정책

- Maven Enforcer로 지원하는 Maven 및 Java 범위를 검사하고 필요한 조직 정책을
  명시적으로 연결합니다.
- 테스트는 `test`, 통합 테스트와 정적 분석을 포함한 전체 검증은 `verify` lifecycle에
  연결합니다.
- CI에서 `-DskipTests` 또는 `-Dmaven.test.skip=true`로 필수 검증을 우회하지 않습니다.
- dependency 충돌은 실제 resolution 결과와 effective POM을 함께 확인합니다.

```sh
./mvnw test
./mvnw verify
./mvnw dependency:tree
./mvnw help:effective-pom
```

- CI와 로컬은 같은 Wrapper와 `verify` 진입점을 사용합니다.
- parent, BOM, Maven 또는 주요 plugin 버전을 변경하면 전체 reactor의 `verify`를
  실행하고 dependency 및 plugin resolution 차이를 검토합니다.

참고: [Maven Wrapper checksum verification](https://maven.apache.org/tools/wrapper/),
[Maven Reproducible Builds](https://maven.apache.org/guides/mini/guide-reproducible-builds.html)
