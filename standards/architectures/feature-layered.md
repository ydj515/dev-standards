# Feature-Layered Architecture Guidelines & Standards

Feature-layered 구조는 기능 package를 먼저 만들고 그 안에서 HTTP, application, domain과
adapter 책임을 나눕니다. 이 저장소에서는 FastAPI 애플리케이션의 기본 profile로 사용하며,
작은 Python module을 유지하기 위해 빈 계층 package 생성을 피합니다.

## 1. 적용 기준

- 기능별 router와 use case가 독립적으로 변경되고 테스트됩니다.
- 전체 애플리케이션을 기술 계층으로 가로지르기보다 관련 코드를 한 feature에 모으는 편이
  탐색과 소유권에 유리합니다.
- HTTP/Pydantic, domain과 persistence model의 책임은 분리해야 합니다.
- 작은 기능은 `domain.py`, `application.py`, `persistence.py`로 평탄화하고 파일이
  커질 때만 하위 package로 확장합니다.

## 2. 기본 구조와 의존 방향

```text
app/
├─ main.py
├─ orders/
│  ├─ domain/
│  │  ├─ models.py                 # Order, OrderId
│  │  ├─ policies.py               # OrderPolicy
│  │  └─ errors.py                 # OrderRejectedError
│  ├─ application/
│  │  ├─ commands.py               # PlaceOrderCommand
│  │  ├─ results.py                # PlaceOrderResult
│  │  ├─ errors.py                 # OrderConflictError
│  │  ├─ ports.py                  # OrderRepository Protocol
│  │  └─ service.py                # place_order
│  ├─ http/
│  │  ├─ router.py
│  │  ├─ schemas.py                # CreateOrderRequest, OrderResponse
│  │  ├─ dependencies.py
│  │  └─ error_handlers.py
│  └─ persistence/
│     ├─ models.py                 # OrderRow
│     └─ repository.py             # SqlOrderRepository
├─ payments/
└─ infrastructure/
   ├─ database.py
   └─ settings.py
```

- 의존 방향은 `http → application → domain`,
  `persistence → application/domain`, `main → 모든 조립 대상`입니다.
- domain과 application은 FastAPI request/response, `HTTPException`과 ORM session을
  참조하지 않습니다.
- application이 소비하는 `Protocol`은 사용하는 feature에 필요한 method만 선언합니다.
- 다른 feature의 `http`나 `persistence` 내부를 직접 import하지 않습니다.

## 3. DTO와 오류 위치

| 종류 | 샘플 파일 | 소유권 |
| --- | --- | --- |
| Request/response schema | `orders/http/schemas.py` | Pydantic validation, alias와 serialization |
| Command/result | `orders/application/{commands,results}.py` | transport와 무관한 use case 계약 |
| Entity/value/policy | `orders/domain/{models,policies}.py` | 업무 규칙과 상태 전이 |
| Domain error | `orders/domain/errors.py` | `OrderRejectedError` 등 업무 거절 |
| Application error/result | `orders/application/errors.py` | 중복 요청과 orchestration 실패 |
| Persistence/client error | adapter module 내부 | 원인 chain 보존과 안정된 오류 변환 |
| HTTP error body/status | `orders/http/error_handlers.py` | 내부 오류를 FastAPI response로 변환 |

기능이 작으면 파일을 합칠 수 있습니다. type 개수가 아니라 독립적인 변경 이유와
재사용 경계가 분리 기준입니다. Pydantic schema를 domain/persistence model로 그대로
재사용하지 않습니다.

## 4. 샘플 요청 흐름

```text
CreateOrderRequest
  → router.create_order
  → PlaceOrderCommand
  → application.service.place_order
  → domain.Order.place
  → OrderRepository Protocol
  → SqlOrderRepository
  → PlaceOrderResult
  → OrderResponse
```

1. router가 schema를 검증하고 command를 생성합니다.
2. application service가 transaction/session 경계와 use case 순서를 소유합니다.
3. domain model이 framework 없이 업무 규칙을 수행합니다.
4. persistence adapter가 Protocol을 구현합니다.
5. error handler가 domain/application 오류를 HTTP status와 body로 변환합니다.

## 5. 경계와 검증

- use case는 FastAPI 없이 단위 테스트하고 router는 dependency override로 contract를
  검증합니다.
- session/resource는 dependency 또는 lifespan에서 commit, rollback과 close 책임을
  명시합니다.
- `async def` 안에서 blocking DB/file/client를 직접 호출하지 않습니다.
- import rule 또는 정적 분석으로 domain/application의 FastAPI·ORM 역방향 의존을
  차단합니다.
- 작은 기능은 평탄화해도 `http → application → domain` 방향을 유지합니다.

## 6. 피해야 할 구조

- route에서 ORM query, transaction, business rule과 response 조립을 모두 수행
- Pydantic request model을 domain entity와 persistence model로 그대로 재사용
- domain exception에 `HTTPException`이나 status code 포함
- Java식 계층을 재현하려고 한 class당 package와 추상 base class 생성
- 다른 feature의 persistence 또는 HTTP 내부 module 직접 import
- `Depends`나 module global을 service locator로 사용

참고: [FastAPI Bigger Applications](https://fastapi.tiangolo.com/tutorial/bigger-applications/),
[FastAPI Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)
