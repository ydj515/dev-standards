# FastAPI Guidelines & Standards

FastAPI 코드는 decorator로 모든 로직을 route에 모으는 방식이 아니라 Python type,
Pydantic model과 dependency graph를 HTTP 계약으로 활용하고 use case는 framework 밖에서
테스트 가능한 구조여야 합니다.

## 1. FastAPI다운 기본 원칙

- path operation은 request parsing, dependency 선언, use case 호출과 response mapping에
  집중합니다.
- request와 response model을 명시하고 내부 ORM/domain 객체를 그대로 반환하지 않습니다.
- type annotation이 validation과 OpenAPI에 반영되므로 `Any`, 무형식 `dict`와 직접 만든
  중복 parsing을 경계에서 피합니다.
- router는 bounded context 또는 API resource 단위로 나누고 application 생성과
  lifecycle 조립은 별도 module에 둡니다.

## 2. FastAPI 적용: feature-layered

FastAPI를 선택하고 `architectures`를 생략하면 `feature-layered` profile을 함께 적용합니다.
기본 구조는 `APIRouter`를 기능별 HTTP entry로 사용하고 FastAPI 조립, use case, domain과
외부 adapter를 분리합니다. Python package 수 자체가 목적은 아니며 작은 기능은 파일을
합칠 수 있지만 import 방향은 유지합니다.

```text
app/
├─ main.py                         # create_app, router/lifespan 조립
├─ orders/
│  ├─ domain.py                    # Order와 domain rule
│  ├─ application.py               # use case와 repository Protocol
│  ├─ http/
│  │  ├─ router.py                 # APIRouter와 HTTP mapping
│  │  ├─ schemas.py                # request/response model
│  │  └─ dependencies.py           # request-scoped adapter 조립
│  └─ persistence.py               # repository 구현
└─ infrastructure/
   ├─ database.py                  # engine/session lifecycle
   └─ settings.py
tests/
├─ unit/orders/
└─ integration/http/
```

- 의존 방향은 `http → application → domain`이며 `persistence`는 application이 요구하는
  `Protocol`을 구현합니다. domain과 application은 FastAPI request/response type을
  참조하지 않습니다.
- `main.py`는 router, exception handler와 lifespan을 조립할 뿐 business rule을 갖지
  않습니다.
- 기능 간 공유는 `common.py`로 옮기기 전에 실제 안정된 계약인지 확인합니다. 다른 기능의
  내부 module을 직접 import하지 않습니다.

```python
from fastapi import FastAPI

from app.orders.http.router import router as orders_router


def create_app() -> FastAPI:
    app = FastAPI()
    app.include_router(orders_router, prefix="/api")
    return app


app = create_app()
```

application factory가 framework lifecycle을 소유하고 router 내부에서는 주입받은 use
case만 호출합니다.

```python
from typing import Annotated

from fastapi import APIRouter, Depends, status

router = APIRouter(prefix="/orders", tags=["orders"])


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    service: Annotated[OrderService, Depends(get_order_service)],
) -> OrderResponse:
    order = await service.load(order_id)
    return OrderResponse.from_domain(order)
```

## 3. Model과 serialization

- input model, output model과 domain model을 역할별로 분리합니다. client가 보낼 수 없는
  field와 server-only field를 같은 model에서 optional로 돌려 쓰지 않습니다.
- response type 또는 `response_model`을 사용해 실제 출력도 검증·filtering되게 합니다.
- alias, timezone, decimal, enum과 unset/null의 wire 의미를 명시합니다.
- validator에서 database나 remote API I/O를 수행하지 않습니다. 구조 검증 이후의
  business validation은 service로 넘깁니다.

## 4. Dependency Injection

- `Depends`는 authentication, request-scoped session, 설정과 adapter 조립처럼 request
  lifecycle에 연결된 dependency에 사용합니다.
- 반복되는 `Annotated` dependency alias로 타입 정보를 유지하고 route signature를
  읽기 쉽게 만듭니다.
- dependency 함수 안에서 service locator나 mutable global을 조회하지 않습니다.
- `yield` dependency로 session/resource를 제공할 때 commit, rollback, close 책임과
  exception 시점을 명확히 합니다.
- test는 `app.dependency_overrides`를 사용하고 종료 후 override를 복원합니다.

## 5. Async와 blocking 경계

- await 가능한 client를 호출하면 `async def`를 사용합니다. blocking library를 직접
  호출하는 route/dependency는 일반 `def`로 두어 FastAPI의 thread pool 경계를
  사용하거나 명시적으로 격리합니다.
- `async def` 안에서 blocking DB/file/network 호출을 실행하지 않습니다.
- CPU 집약 작업을 event loop 또는 request worker에서 장시간 처리하지 않고 별도 worker
  경계를 고려합니다.
- background task는 응답 이후에도 필요한 durability, retry와 관찰성이 있으면 durable
  queue를 사용합니다. in-process task를 job system처럼 사용하지 않습니다.

## 6. 오류와 HTTP 의미

- domain/application layer는 HTTP 상태를 모르고 의미 있는 domain error를 반환합니다.
- exception handler가 domain error를 안정적인 status와 error body로 한 번 변환합니다.
- `HTTPException`은 route/dependency의 HTTP 경계에 한정하고 service 깊숙이 전파하지
  않습니다.
- 401과 403, 404와 409, validation 422의 의미를 API contract에서 일관되게 사용합니다.
- 내부 exception message, SQL, token과 stack trace를 response에 노출하지 않습니다.

## 7. Security와 lifecycle

- 인증·인가 dependency를 router 또는 route에 명시하고 “로그인했음”과 resource 권한을
  구분합니다.
- upload size, content type, pagination limit과 outbound timeout을 경계에서 제한합니다.
- startup/shutdown resource는 lifespan context에서 만들고 module import side effect로
  연결하지 않습니다.
- proxy header, CORS와 trusted host 설정은 실제 deployment topology에 맞게 구성합니다.

## 8. 테스트와 품질 게이트

- use case는 FastAPI 없이 단위 테스트하고 route는 dependency override를 사용해 HTTP
  status, validation과 serialization을 검증합니다.
- async test와 client의 event loop/lifespan 동작을 일치시키고 startup 누락을 숨기지
  않습니다.
- 생성된 OpenAPI diff를 공개 API 변경 검토에 포함합니다.

```sh
uv run --frozen pytest
ruff check .
ruff format --check .
pyright
```

## 9. FastAPI 안티패턴

- route에서 ORM query, transaction, business rule과 response dictionary 조립을 모두 수행
- 모든 path operation을 무조건 `async def`로 만들고 blocking I/O 실행
- input/output/ORM model 하나를 공용으로 사용
- dependency graph를 service locator나 숨은 global state로 사용

참고: [FastAPI Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/),
[Response Models](https://fastapi.tiangolo.com/tutorial/response-model/),
[Concurrency and async](https://fastapi.tiangolo.com/async/),
[Bigger Applications](https://fastapi.tiangolo.com/tutorial/bigger-applications/)
