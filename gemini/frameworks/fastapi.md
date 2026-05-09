# FastAPI Code Review Guidelines

이 문서는 FastAPI 기반 Python 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.
목표는 **명확한 API 계약**, **Pydantic 기반 검증 일관성**, **비동기 경계의 안전성**, **의존성 주입과 계층 분리**를 확보하는 것입니다.

---

## 1. Route Layer Responsibility

- path operation 함수가 요청/응답 변환과 orchestration 책임에 머무르는지 확인
- 비즈니스 로직, DB 접근, 외부 API 호출이 route 함수에 직접 쌓이지 않는지 점검
- HTTP 계층의 관심사(status code, request parsing, auth)와 도메인 로직이 분리되어 있는지 검토

### 리뷰 질문

- 이 로직은 라우터에 있어야 하는가, 서비스 계층에 있어야 하는가?
- FastAPI가 제공하는 선언적 기능으로 더 명확하게 표현할 수 없는가?

---

## 2. Request / Response Modeling

- request body, query, path parameter가 Pydantic 모델 또는 명시적 타입으로 충분히 표현되는지 확인
- response model이 실제 반환 구조와 일치하는지 점검
- DB 엔티티나 내부 도메인 객체를 그대로 응답으로 노출하지 않는지 검토
- optional 필드와 기본값이 API 계약상 의미에 맞게 설계되었는지 확인

### 좋은 패턴

```python
class CreateUserRequest(BaseModel):
    email: EmailStr
    name: constr(min_length=1, max_length=50)


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    name: str
```

---

## 3. Validation & Serialization

- 검증 로직을 route 함수 내부 수동 `if` 문으로 반복하지 않는지 확인
- Pydantic validator, field constraint, custom type으로 계약을 선언적으로 표현하는지 점검
- 직렬화 정책(alias, exclude, ORM mode/attribute access)이 일관적인지 검토
- datetime, enum, decimal 같은 타입이 API에서 예측 가능하게 직렬화되는지 확인

---

## 4. Dependency Injection

- `Depends`를 활용하되, 의존성 그래프가 지나치게 복잡해지지 않는지 확인
- DB session, 인증 사용자, 설정 객체 등 요청 범위 의존성이 명확히 분리되는지 점검
- 의존성 함수가 숨은 비즈니스 로직 저장소처럼 비대해지지 않는지 검토

### 흔한 안티패턴

```python
async def get_user_service():
    repository = UserRepository(SessionLocal())
    notifier = SlackNotifier(...)
    return UserService(repository, notifier)
```

- 리소스 lifecycle, 테스트 대체, 설정 주입이 불투명해질 수 있음

---

## 5. Async vs Sync 경계

- `async def` route 안에서 blocking DB driver, 파일 I/O, 외부 HTTP 호출을 직접 사용하지 않는지 확인
- sync 함수면 굳이 async로 선언하지 않는지 점검
- 병렬 처리 가능한 외부 호출을 순차 await 하지 않는지 검토
- CPU bound 작업을 event loop에서 직접 오래 점유하지 않는지 확인

---

## 6. Error Handling & HTTP Semantics

- `HTTPException` 사용이 단순한 프레임워크 예외 처리인지, 도메인 예외까지 모두 라우터에서 직접 분기하는 구조인지 점검
- 공통 예외는 exception handler로 일관되게 매핑하는지 검토
- status code가 의도에 맞는지 확인 (`200`, `201`, `204`, `400`, `404`, `409`, `422` 등)
- 에러 응답 형식이 프로젝트 전반에서 일관적인지 점검

### 더 나은 패턴

```python
@app.exception_handler(UserNotFoundError)
async def handle_user_not_found(_: Request, exc: UserNotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"message": str(exc)})
```

---

## 7. Security & Auth

- 인증/인가가 dependency 또는 명시적 계층으로 일관되게 적용되는지 확인
- 민감 정보가 response model, 로그, OpenAPI schema 예시에 노출되지 않는지 점검
- 파일 업로드, query 파라미터, 헤더 입력값이 검증 없이 사용되지 않는지 검토
- CORS, 쿠키, 토큰 처리 방식이 배포 환경 요구사항에 맞는지 확인

---

## 8. Database & Session Management

- 요청 단위 session lifecycle이 안전하게 관리되는지 확인
- lazy loading이나 ORM 객체 직렬화가 route 밖 계약을 흐리지 않는지 점검
- 트랜잭션 경계가 서비스 계층 또는 명확한 단위에 있는지 검토
- N+1, 과도한 eager loading, 불필요한 commit/flush가 없는지 확인

---

## 9. OpenAPI & Documentation

- path summary, description, response model, error response가 충분히 문서화되는지 확인
- API 문서가 실제 구현과 어긋나지 않는지 점검
- deprecated endpoint, internal endpoint 노출 전략이 분명한지 검토

---

## 10. Testing

- dependency override를 활용해 DB, auth, 외부 API를 테스트에서 분리할 수 있는지 확인
- request validation, auth failure, error mapping, success path가 함께 검증되는지 점검
- async 테스트 전략이 프로젝트 전반에서 일관적인지 검토

---

## 11. FastAPI 안티패턴

- route 함수 안에 비즈니스 로직과 DB 호출이 가득한 구조
- Pydantic 검증을 우회하고 수동 `if` 문으로 계약을 처리하는 패턴
- async route 안에서 blocking I/O를 직접 호출하는 구현
- 내부 ORM 객체를 그대로 응답으로 반환하는 방식
- `Depends` 체인이 과도하게 비대해져 실제 흐름을 읽기 어려운 상태

---

## 12. FastAPI 좋은 패턴

- request/response 모델이 명확하고 Pydantic 검증이 일관되게 적용된 구조
- route, service, repository 책임이 분리된 계층형 설계
- 예외를 공통 handler로 매핑해 HTTP 계약을 일관되게 유지하는 방식
- 요청 범위 의존성과 리소스 lifecycle이 명확한 dependency 구성
- async/sync 경계를 분명히 구분해 event loop를 안전하게 사용하는 구현

---

## 리뷰 시 핵심 질문

- API 계약이 코드만 봐도 명확하게 드러나는가?
- FastAPI의 선언적 검증과 의존성 주입을 제대로 활용하고 있는가?
- async 경계가 안전하며 blocking 작업이 숨어 있지 않은가?
- route 함수가 얇고 테스트 가능한 구조를 유지하는가?
