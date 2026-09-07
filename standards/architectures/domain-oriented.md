# Domain-Oriented Architecture Guidelines & Standards

Domain-oriented 구조는 기술 계층보다 업무 능력과 bounded context를 최상위 경계로 둡니다.
언어와 프레임워크에 독립적인 package/module 원칙이며, Go에서는 작은 package로,
Spring에서는 bounded context 내부 계층으로 구체화할 수 있습니다. 이 profile이 모든
DDD 전술 패턴을 의무화하지는 않습니다.

## 1. 적용 기준

- 독립된 용어, 규칙, 데이터 수명 주기와 변경 이유를 가진 업무 영역을 bounded context로
  식별합니다.
- 최상위 package/module은 `order`, `payment`, `inventory`처럼 업무 능력을 드러냅니다.
- context 공개 API는 application operation과 안정된 값만 노출하고 내부 entity,
  persistence model과 framework request type을 공유하지 않습니다.
- aggregate, repository, domain event는 실제 불변식과 협력 규칙이 있을 때 도입합니다.
  단순 CRUD에 DDD 형태만 복제하지 않습니다.

## 2. 기본 구조와 의존 방향

`<ext>`는 선택 언어의 확장자로 바꿉니다. Go의 구체적인 평탄화 구조는 언어 가이드가
추가로 정의합니다.

```text
<application-root>/
├─ order/                              # bounded context
│  ├─ presentation/
│  │  ├─ OrderController.<ext>
│  │  ├─ request/CreateOrderRequest.<ext>
│  │  ├─ response/OrderResponse.<ext>
│  │  └─ OrderErrorMapper.<ext>
│  ├─ application/
│  │  ├─ PlaceOrderUseCase.<ext>
│  │  ├─ command/PlaceOrderCommand.<ext>
│  │  ├─ result/PlaceOrderResult.<ext>
│  │  ├─ exception/OrderConflict.<ext>
│  │  └─ port/out/PaymentGateway.<ext>
│  ├─ domain/
│  │  ├─ model/Order.<ext>
│  │  ├─ model/OrderId.<ext>
│  │  ├─ repository/OrderRepository.<ext>
│  │  ├─ policy/OrderPolicy.<ext>
│  │  ├─ event/OrderPlaced.<ext>
│  │  └─ exception/OrderRejected.<ext>
│  └─ infrastructure/
│     ├─ persistence/OrderRecord.<ext>
│     ├─ persistence/OrderRepositoryAdapter.<ext>
│     └─ client/PaymentClientAdapter.<ext>
├─ payment/
└─ config/ApplicationConfig.<ext>      # composition root
```

- context 내부 방향은 `presentation → application → domain`,
  `infrastructure → application/domain`, `config → 모든 조립 대상`입니다.
- `domain`은 framework와 바깥 계층을 참조하지 않습니다.
- `application`은 use case와 transaction을 소유하고 presentation DTO나 concrete
  adapter를 참조하지 않습니다.
- context 간 협력은 공개 application API, 식별자/value contract 또는 event를 사용합니다.
  상대 context의 aggregate와 repository를 직접 import하지 않습니다.

`layered-clean`과 내부 방향은 비슷하지만 최상위 분할이 다릅니다.
`layered-clean`은 `presentation/order`처럼 계층 우선이고, `domain-oriented`는
`order/presentation`처럼 bounded context 우선입니다.

## 3. DTO와 오류 위치

| 종류 | 샘플 파일 | 소유권 |
| --- | --- | --- |
| 외부 request | `order/presentation/request/CreateOrderRequest.<ext>` | protocol field, validation과 역직렬화 |
| 외부 response | `order/presentation/response/OrderResponse.<ext>` | status에 맞는 공개 응답 |
| Use case 입력/출력 | `order/application/{command,result}/PlaceOrder*.<ext>` | transport와 무관한 operation 계약 |
| Entity/value/policy | `order/domain/model/Order.<ext>`, `policy/OrderPolicy.<ext>` | 불변식과 상태 전이 |
| Domain error/result | `order/domain/exception/OrderRejected.<ext>` | 업무 규칙에 따른 거절 |
| Application error/result | `order/application/exception/OrderConflict.<ext>` | 권한, 중복 요청과 orchestration 실패 |
| Infrastructure error | `order/infrastructure/persistence/OrderRepositoryAdapter.<ext>` 내부 | 기술 원인 보존과 안정된 오류 변환 |
| 외부 error contract | `order/presentation/OrderErrorMapper.<ext>` | HTTP/message/CLI 의미로 변환 |

모양이 같아도 외부 호환성 요구가 domain model을 지배하면 type을 분리합니다. 반대로
의미와 변경 주기가 같다면 계층마다 동일한 DTO를 기계적으로 복제하지 않습니다. 오류의
구현은 Go `error`, Kotlin/Java exception 또는 sealed result처럼 언어 관용구를 따릅니다.

## 4. 샘플 요청 흐름

```text
CreateOrderRequest
  → OrderController
  → PlaceOrderCommand
  → PlaceOrderUseCase
  → Order.place(...)
  → OrderRepository.save(...)
  → PlaceOrderResult
  → OrderResponse
```

1. presentation이 request를 검증하고 command로 변환합니다.
2. application이 transaction과 협력 순서를 소유합니다.
3. domain aggregate가 불변식을 검사하고 상태를 변경합니다.
4. infrastructure adapter가 domain repository/output port를 구현합니다.
5. presentation이 result 또는 내부 오류를 외부 response로 변환합니다.

## 5. 경계와 검증

- aggregate는 하나의 transaction에서 지켜야 하는 불변식과 일관성 경계가 있을 때
  사용합니다. table마다 aggregate를 만들지 않습니다.
- aggregate repository는 domain contract에 두고, 화면 projection과 외부 gateway처럼
  use case 전용인 계약은 application output port에 둡니다.
- domain event는 이미 발생한 업무 사실을 표현하며 delivery, retry, idempotency와
  outbox가 필요하면 함께 설계합니다.
- domain/application은 framework 없이 단위 테스트하고 adapter contract와 context 간
  금지 import는 integration/architecture test로 검증합니다.
- 작은 기능은 파일과 package를 합칠 수 있지만 책임 소유권과 의존 방향은 유지합니다.

## 6. 피해야 할 구조

- 모든 context에 동일한 controller/service/repository/interface 뼈대를 미리 생성
- context 이름만 나누고 서로의 entity와 repository를 자유롭게 import
- request DTO를 application/domain까지 전달하거나 persistence model을 외부 응답으로 노출
- aggregate, domain service와 event를 단순 CRUD에도 형식적으로 추가
- `common`, `shared`, `base`가 모든 context의 domain model을 모으는 우회 의존성이 됨
