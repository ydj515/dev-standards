# Java Code Review Guidelines

이 문서는 Java 기반 프로젝트에서 Gemini가 추가로 고려해야 할 규칙입니다.

---

## 1. Idiomatic Java

- Stream API, Lambda, Optional을 적절히 활용했는지 확인
- 불필요한 for-loop → Stream 변환 제안 가능
- Java 17+ 환경에서는 `record` 사용 고려 제안

---

## 2. Persistence & Transaction

- **N+1 문제** 발생 가능성 검토
  - 반복문 내 Repository 호출 여부 확인
- Transaction 범위가 과도하게 넓지 않은지 검토
- Read-only 트랜잭션 최적화 여부 확인

---

## 3. Exception Handling

- 체크 예외를 무분별하게 throws 하지 않았는지 검토
- 비즈니스 예외 vs 시스템 예외 구분 제안
- Controller 계층에서 HTTP Status 매핑 적절성 검토

---

## 4. Spring / JPA 관점 (해당 시)

- Entity에 비즈니스 로직 과다 포함 여부
- Lazy Loading으로 인한 사이드 이펙트 가능성

---

## 5. Java 안티패턴

- getter/setter 중심의 빈약한 도메인 모델과 거대한 서비스 클래스 조합
- `Optional`을 반환값이 아닌 필드/파라미터에 무분별하게 사용하는 패턴
- 스트림이 더 복잡해졌는데도 “함수형”이라는 이유만으로 유지하는 코드
- 예외를 너무 넓게 잡거나 checked exception을 무의미하게 상위로 전파하는 방식
- JPA 엔티티를 API 응답, 서비스 경계, 뷰 모델에 그대로 퍼뜨리는 구조
- 루프 내부 Repository 호출로 N+1을 유발하는 구현

---

## 6. Java 좋은 패턴

- `record`, `enum`, 명확한 DTO/도메인 타입으로 경계를 분리하는 구조
- stream/lambda를 읽기 쉬운 범위에서만 사용하고, 복잡하면 명시적 루프로 돌아가는 판단
- 예외를 비즈니스 의미에 맞게 분리하고 HTTP/API 경계에서 일관되게 매핑하는 방식
- 트랜잭션 경계와 영속성 접근 책임이 서비스/리포지토리 계층에 분명히 나뉜 설계
- 컬렉션 처리, null 처리, 불변성 유지가 코드 의도를 명확히 드러내는 구현

---

## 리뷰 시 핵심 질문

- 이 코드는 Java답게 명확하고 유지보수하기 쉬운가?
- 타입과 객체 구조가 도메인 의도를 충분히 표현하는가?
- 예외와 트랜잭션 경계가 호출 흐름에 맞게 설계되어 있는가?
- JPA/Spring 사용이 편의성만 높이고 결합도나 성능 문제를 숨기고 있지는 않은가?
