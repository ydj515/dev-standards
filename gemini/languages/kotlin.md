# Kotlin Code Review Guidelines

이 문서는 Kotlin 프로젝트에서 Gemini가 추가로 고려해야 할 규칙입니다.

---

## 1. Idiomatic Kotlin

- 불필요한 Java 스타일(예: 과도한 Getter/Setter) 대신 Kotlin 표준 관용구 사용 여부 확인
- `data class`, `sealed class`, `object` 사용이 적절한지 검토
- `when` 분기에서 누락 케이스가 없는지 확인 (가능하면 `else` 대신 모든 케이스 명시)
- 상태가 없고 재사용되는 로직은 **확장 함수**로 추출할 수 있는지 검토
  - 수신 객체의 의미가 명확하고 의도를 드러내는 경우 확장 함수 사용을 제안
  - 도메인 로직을 무분별하게 확장 함수로 퍼뜨려 응집도를 해치지 않는지 확인

### 확장 함수 사용 기준 (When to use)
- **수신 객체가 명확한 단일 책임**을 가질 때 (예: 문자열 포맷, 컬렉션 필터링)
- **상태가 없고 순수 함수** 성격일 때
- **호출부 가독성 개선**이 되는 경우 (`user.isAdult()` 등)
- **기본 타입/표준 타입에 도메인 의미를 부여**할 때 (예: `String.toUserId()`)

### 확장 함수 지양 기준 (When not to use)
- **은닉되어야 할 내부 로직**을 확장 함수로 노출하는 경우
- **수신 객체 의미가 모호**하거나 강한 결합을 유발하는 경우
- **동일 도메인 로직이 여러 파일로 분산**되어 응집도가 깨지는 경우
- **테스트 대체/모킹이 중요한 객체**에 과도하게 확장 함수를 사용하는 경우

### 예시

```kotlin
// 좋은 예: 수신 객체 의미가 명확하고 가독성 개선
fun String.toUserId(): UserId {
    // 문자열을 도메인 식별자로 변환
    return UserId(this.trim())
}

// 좋은 예: 컬렉션 유틸 성격, 상태 없음
fun List<Order>.totalAmount(): Money {
    // 주문 금액 합산
    return this.fold(Money.zero()) { acc, order -> acc + order.amount }
}

// 나쁜 예: 도메인 로직이 분산되고 결합이 강해짐
fun User.toPaymentSummary(repo: PaymentRepository): PaymentSummary {
    // 외부 의존성 주입을 강요하여 응집도 저하
    return repo.findByUserId(this.id).toSummary()
}
```

---

## 6. 확장 함수 vs 톱레벨 함수 vs 유틸 객체

| 구분 | 언제 선택하는가 | 장점 | 단점 | 테스트 용이성 |
| --- | --- | --- | --- |
| 확장 함수 | 수신 객체의 의미가 명확하고, 호출부 가독성이 좋아지는 경우 | 호출부가 읽기 쉬움, 도메인 표현력이 높아짐 | 남용 시 로직 분산, 결합도 증가 | 보통 (정적 확장으로 대체/모킹이 제한됨) |
| 톱레벨 함수 | 수신 객체가 모호하거나 다수 입력을 다루는 경우 | 의존성이 명확하고 테스트가 단순함 | 호출부가 길어질 수 있음 | 좋음 (의존성 주입 없이 단위 테스트 용이) |
| 유틸 객체 | 상태 공유가 필요하거나 이름공간이 필요한 경우 | 관련 함수 묶음으로 가독성 개선 | 전역 접근으로 남용 가능, 테스트 대체가 어려워짐 | 낮음 (전역 접근으로 대체/모킹이 어려움) |

---

## 7. object vs companion object 선택 기준

| 구분 | 언제 선택하는가 | 장점 | 단점 | 테스트 용이성 |
| --- | --- | --- | --- | --- |
| `object` | 독립적인 싱글턴이 필요하거나, 명시적 이름공간을 제공하고 싶은 경우 | 명확한 역할 분리, 선언이 단순함 | 전역 싱글턴 남용 위험 | 낮음 (전역 접근으로 대체/모킹이 어려움) |
| `companion object` | 클래스와 강하게 결합된 정적 동작이 필요할 때 (팩토리, 상수) | 클래스 맥락에서 발견 가능, 접근이 자연스러움 | 클래스 책임이 비대해질 수 있음 | 보통 (의존성 분리가 필요할 수 있음) |

---

## 2. Null Safety

- 플랫폼 타입(`String!`) 노출 최소화 여부 확인
- `!!` 남용 여부 확인 및 안전한 대체(`?.`, `?:`, `let`) 제안
- nullable/ non-nullable 경계가 명확한지 검토

---

## 3. Collection & Functional Style

- `map`, `filter`, `fold` 등 표준 컬렉션 연산 활용 가능성 검토
- 불필요한 중첩 루프를 `sequence` 또는 스트림 파이프라인으로 단순화 제안
- 성능 이슈가 있는 곳에서 `Sequence` 사용 여부 검토

---

## 4. Coroutine & Concurrency

- `suspend` 함수 사용 시 구조적 동시성 준수 여부 확인
- `GlobalScope` 사용 지양 제안
- 적절한 Dispatcher 사용 여부 검토 (`IO`, `Default`, `Main`)

---

## 5. Java Interop

- Java 라이브러리 호출 시 null 처리 전략 확인
- `@JvmStatic`, `@JvmOverloads`, `@JvmField` 사용이 과도하지 않은지 검토
- 컬렉션 변환 비용(`asList`, `toList`)을 불필요하게 유발하지 않는지 확인
