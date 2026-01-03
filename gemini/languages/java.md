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
