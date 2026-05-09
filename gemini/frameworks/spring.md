# Spring Framework Code Review Guidelines

이 문서는 **Spring Framework (Spring Boot, Spring MVC, Spring Data JPA)** 기반 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.
목표는 **계층 책임 분리**, **트랜잭션과 영속성 경계의 명확화**, **검증과 보안의 일관성**, **운영 안정성**을 함께 확보하는 것입니다.

Base 및 Language(Java) 가이드를 전제로 하며, Spring 특유의 구조와 관례, 자주 놓치는 함정에 집중합니다.

---

## 1. Layered Architecture & Responsibility

- Controller / Service / Repository 간 책임이 명확히 분리되어 있는지 확인
- Controller는 요청 파싱, 응답 변환, 유효성 검증에 집중하고 비즈니스 로직을 직접 수행하지 않는지 점검
- Service는 비즈니스 규칙과 트랜잭션 경계를 담당하고, Repository는 영속성 접근에만 머무르는지 검토
- Scheduler, Event Listener, Batch Job에서도 동일한 책임 분리가 유지되는지 확인

### 리뷰 질문

- 이 로직은 정말 Controller에 있어야 하는가?
- 트랜잭션과 도메인 규칙이 Service 계층에 모여 있는가?

---

## 2. DTO vs Entity Boundary

- API 요청/응답에 Entity를 직접 노출하지 않는지 확인
- 요청 DTO, 응답 DTO, 도메인 모델의 경계가 명확한지 점검
- Controller가 Entity의 지연 로딩 필드나 깊은 연관관계를 직접 탐색하지 않는지 검토
- 화면/API 요구사항 때문에 Entity 구조가 왜곡되고 있지 않은지 확인

---

## 3. Dependency Injection & Bean Design

- 필드 주입보다 생성자 주입을 사용하는지 확인
- Singleton Bean이 상태를 가지지 않는지 점검
- 지나치게 많은 의존성을 주입받는 Service는 책임 과다 여부를 검토
- static util이나 전역 접근보다 명시적 의존성 주입이 유지보수에 유리한지 확인

### 좋은 예

```java
@RequiredArgsConstructor
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway;
}
```

---

## 4. Transaction Management

- `@Transactional`이 Service 계층의 명확한 유스케이스 경계에 선언되어 있는지 확인
- 조회 전용 로직에 `@Transactional(readOnly = true)`를 적용할 수 있는지 검토
- 외부 API 호출, 파일 I/O, 대기 시간이 긴 작업을 긴 트랜잭션 안에 묶지 않았는지 점검
- 전파 옵션과 격리 수준이 기본값이 아닌 경우, 분명한 의도와 설명이 있는지 확인
- 같은 클래스 내부 self-invocation, private method 호출처럼 프록시 기반 트랜잭션이 적용되지 않는 함정을 밟고 있지 않은지 검토

---

## 5. Persistence & Query Design

- 반복문 내부 Repository 호출, 화면 렌더링 중 지연 로딩 등으로 N+1 문제가 생기지 않는지 확인
- `fetch join`, `@EntityGraph`, 배치 페치, DTO projection 중 상황에 맞는 전략을 선택했는지 검토
- OSIV에 암묵적으로 기대어 Controller/View 계층에서 Entity를 계속 탐색하지 않는지 점검
- 벌크 연산 후 영속성 컨텍스트 동기화(clear/flush)가 필요한지 확인
- 페이징 쿼리와 컬렉션 fetch join을 무리하게 결합해 성능/정합성 문제가 생기지 않는지 검토

---

## 6. Entity Design

- Entity가 도메인 불변식과 핵심 행위를 담되, 인프라/프레젠테이션 책임까지 떠안지 않는지 확인
- 양방향 연관관계를 기본값처럼 만들지 않고, 필요한 경우에만 최소화하는지 점검
- `equals` / `hashCode` 구현이 식별자와 영속성 생명주기를 고려하는지 검토
- 컬렉션 초기화, 생성 메서드, 상태 변경 메서드가 도메인 규칙을 드러내는지 확인

---

## 7. Web Layer & Validation

- `@Valid`, `@Validated`, Bean Validation을 일관되게 사용하는지 확인
- Controller에서 수동 문자열 파싱, null 체크, 비즈니스 조건 검증이 반복되지 않는지 점검
- 요청 파라미터, path variable, body validation 실패 시 응답 형식이 일관적인지 검토
- HTTP status code와 응답 스키마가 API 계약에 맞게 유지되는지 확인

---

## 8. Exception Handling

- `@ControllerAdvice` 기반 전역 예외 처리 전략이 존재하는지 확인
- 비즈니스 예외와 시스템 예외가 구분되어 있는지 점검
- 내부 구현 세부사항, SQL 메시지, stack trace가 외부 응답에 노출되지 않는지 검토
- 같은 예외를 여러 계층에서 중복 로깅해 노이즈를 만들고 있지 않은지 확인

---

## 9. Security & Authorization

- 인증이 필요한 엔드포인트와 서비스가 일관되게 보호되는지 확인
- 권한 체크를 Controller 한 곳에만 두고 Service/도메인 경계에서 빠뜨리지 않는지 점검
- 민감 정보(토큰, 비밀번호, 주민번호 등)가 로그, 예외 메시지, 응답 DTO에 노출되지 않는지 검토
- 파일 업로드, 검색 조건, 정렬 파라미터 등 외부 입력이 검증 없이 쿼리나 리소스 접근에 사용되지 않는지 확인

---

## 10. Configuration & Properties

- URL, timeout, feature flag, 자격 증명 등 설정값이 하드코딩되지 않았는지 확인
- 흩어진 `@Value`보다 `@ConfigurationProperties`로 의미 있는 설정 단위를 묶을 수 있는지 검토
- `dev`, `test`, `prod` profile 경계가 명확하고 환경별 설정 혼선이 없는지 점검
- 시작 시점 검증이 필요한 설정값은 fail-fast 하도록 설계되어 있는지 확인

---

## 11. Logging & Observability

- info / warn / error 레벨이 상황에 맞게 사용되는지 확인
- 예외 발생 시 원인 파악에 필요한 문맥(request id, entity id 등)이 로그에 포함되는지 점검
- PII, 토큰, 비밀번호, 카드 정보 등 민감 데이터가 로그에 남지 않는지 검토
- 느린 쿼리, 외부 API 지연, 재시도 실패 같은 운영 이슈를 추적할 수 있는지 확인

---

## 12. Testing Strategy

- 단순 단위 로직 테스트에 `@SpringBootTest`를 기본값처럼 사용하지 않는지 확인
- `@WebMvcTest`, `@DataJpaTest` 같은 slice test를 적절히 활용하는지 점검
- Repository, Query, Transaction 동작처럼 실제 인프라 영향이 큰 영역은 통합 테스트가 있는지 검토
- 테스트 간 DB 상태, 캐시, 이벤트 리스너 영향이 격리되는지 확인
- Testcontainers 등 실제 의존성을 반영한 검증이 필요한 구간을 식별하고 있는지 점검

---

## 13. Spring 안티패턴

- Controller에 비즈니스 로직, 트랜잭션, 영속성 접근이 몰려 있는 구조
- Entity를 요청/응답 DTO처럼 직접 노출하는 패턴
- `@Transactional`을 습관적으로 붙이고 경계를 설명하지 않는 코드
- OSIV에 기대어 화면/API 직전까지 Entity 그래프를 탐색하는 구현
- 큰 Service가 너무 많은 Repository와 외부 클라이언트를 동시에 주입받는 상태
- 전역 예외 처리 없이 Controller마다 `try-catch`를 반복하는 방식

---

## 14. Spring 좋은 패턴

- Controller, Service, Repository, DTO 경계가 명확한 계층형 설계
- 트랜잭션 경계와 조회/변경 의도가 코드에서 자연스럽게 드러나는 구현
- N+1과 지연 로딩 함정을 인지하고 조회 전략을 명시적으로 선택하는 방식
- Validation, Exception Mapping, Security 정책이 전역적으로 일관된 API 계층
- 설정, 로깅, 테스트 전략이 운영 환경까지 고려해 정리된 구조

---

## 리뷰 시 핵심 질문

- 이 로직은 Spring 계층 구조 안에서 올바른 위치에 있는가?
- 트랜잭션과 영속성 컨텍스트의 경계가 성능과 정합성 측면에서 안전한가?
- Validation, 예외 처리, 보안 정책이 엔드포인트 전반에서 일관적인가?
- 지금 편의를 위해 OSIV, Entity 노출, 과한 의존성 같은 장기 리스크를 숨기고 있지는 않은가?
