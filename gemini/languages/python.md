# Python Code Review Guidelines

이 문서는 Python 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 규칙을 정리한 가이드입니다.
목표는 **가독성**, **명확한 데이터 모델링**, **예외 처리의 일관성**, **타입 안정성**, **테스트 용이성**을 함께 확보하는 것입니다.

---

## 1. Pythonic Code

- 불필요하게 Java/C 스타일로 작성된 코드를 Python답게 단순화할 수 있는지 확인
- comprehension, generator, unpacking, context manager를 적절히 활용하는지 검토
- 한 줄로 줄일 수 있다는 이유만으로 과도한 축약 표현을 사용하지 않는지 점검
- 명시성이 가독성을 해치지 않는 선에서 유지되는지 확인

### 좋은 예

```python
active_users = [user for user in users if user.is_active]
```

- 단순 필터링은 명확한 comprehension이 읽기 쉬움

---

## 2. Function Design & Readability

- 함수가 하나의 책임만 가지는지 확인
- 매개변수가 너무 많거나 boolean 플래그가 늘어나는 함수는 분리 후보로 검토
- 함수/변수 이름이 역할을 설명하는지 점검
- 중첩 분기를 줄이고 early return으로 의도를 드러낼 수 있는지 확인

### 흔한 안티패턴

```python
def process(data, flag, mode, verbose=False):
    if data is not None:
        if flag:
            if mode == "A":
                ...
```

- 역할이 모호하고 분기가 깊어질수록 테스트와 수정이 어려워짐

### 더 나은 패턴

```python
def process_order(order: Order, mode: ProcessingMode) -> ProcessResult:
    if order.is_cancelled():
        return ProcessResult.skipped("cancelled")

    if mode is ProcessingMode.SYNC:
        return process_sync(order)

    return process_async(order)
```

---

## 3. Type Hinting & Data Modeling

- 공개 함수, 서비스 경계, 복잡한 반환값에 type hint가 충분한지 확인
- `dict[str, Any]`로 모든 도메인 데이터를 뭉개고 있지 않은지 점검
- `dataclass`, `TypedDict`, `Protocol`, `Enum` 등으로 구조를 명확히 표현할 수 있는지 검토
- 런타임 검증이 필요한 외부 입력과 내부 도메인 모델이 구분되는지 확인

### 좋은 패턴

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class UserSummary:
    id: int
    name: str
    is_active: bool
```

---

## 4. Error Handling

- 광범위한 `except Exception` 사용이 정말 필요한지 검토
- 예외를 잡는다면 복구, 변환, 로깅 중 어떤 목적 때문인지 분명한지 확인
- 예외를 삼키고 `None`, `False`, 빈 리스트로 대충 대체하지 않는지 점검
- 라이브러리/인프라 예외를 도메인 의미가 있는 예외로 변환할 필요가 있는지 검토

### 흔한 안티패턴

```python
try:
    return repository.save(user)
except Exception:
    return None
```

- 실패 원인이 숨겨져 디버깅과 호출부 처리 모두 어려워짐

### 더 나은 패턴

```python
try:
    return repository.save(user)
except DuplicateEmailError as exc:
    raise UserRegistrationError("email already exists") from exc
```

---

## 5. Resource Management & I/O

- 파일, 소켓, DB 연결, 락 등을 `with` 또는 명시적 lifecycle로 안전하게 관리하는지 확인
- I/O와 비즈니스 로직이 한 함수에 섞여 테스트가 어려워지지 않는지 점검
- 대용량 파일/응답을 전부 메모리에 올리지 않아도 되는 구조인지 검토

---

## 6. Collection Processing & Performance

- 단순 반복/변환/집계는 표준 컬렉션 연산으로 명확하게 표현하는지 확인
- 중첩 루프, 반복 membership 검사처럼 명백히 비효율적인 패턴이 없는지 점검
- generator가 더 적합한 곳에서 불필요하게 리스트를 만들고 있지 않은지 검토
- 반대로 지나친 generator 체인이 가독성을 해치지 않는지도 확인

---

## 7. Mutability & Default Arguments

- mutable default argument(`[]`, `{}`)를 사용하지 않는지 확인
- 함수가 입력 객체를 암묵적으로 변경하지 않는지 점검
- 공유 상태를 수정하는 코드라면 동시성/재진입성 문제가 없는지 검토

### 흔한 안티패턴

```python
def add_tag(tag: str, tags: list[str] = []):
    tags.append(tag)
    return tags
```

### 더 나은 패턴

```python
def add_tag(tag: str, tags: list[str] | None = None) -> list[str]:
    current_tags = [] if tags is None else list(tags)
    current_tags.append(tag)
    return current_tags
```

---

## 8. Async & Concurrency

- `async def`가 실제로 비동기 I/O 경계에서만 사용되는지 확인
- async 함수 안에서 blocking I/O를 직접 호출하지 않는지 점검
- 병렬 실행 가능한 작업을 순차 await 하고 있지 않은지 검토
- 공유 mutable state를 여러 coroutine/thread가 동시에 수정하지 않는지 확인

---

## 9. Imports, Module Structure & Dependency

- 순환 참조 가능성이 없는지 점검
- 모듈이 너무 많은 책임을 가지지 않는지 확인
- 내부 구현 세부사항이 외부에 과도하게 노출되지 않는지 검토
- `utils.py`, `helpers.py`, `common.py`에 무분별하게 로직이 쌓이고 있지 않은지 점검

---

## 10. Testing & Observability

- 순수 함수와 I/O 경계가 분리되어 테스트 가능한 구조인지 확인
- 시간, UUID, 환경변수, 외부 API 같은 비결정 요소가 추상화되어 있는지 점검
- 실패 시 로그만 남기고 호출부 계약이 모호해지지 않는지 검토
- 로그에 개인정보, 토큰, 비밀번호 등 민감값이 남지 않는지 확인

---

## 11. Python 안티패턴

- `except Exception`으로 모든 오류를 삼키는 패턴
- mutable default argument 사용
- `dict[str, Any]`와 문자열 키에만 의존하는 느슨한 데이터 구조
- I/O, 파싱, 비즈니스 로직이 한 함수에 섞여 있는 구조
- comprehension이나 generator를 과하게 중첩해 읽기 어려워진 코드
- `utils.py`에 도메인 로직이 계속 누적되는 상태

---

## 12. Python 좋은 패턴

- `dataclass`, `Enum`, type hint로 경계를 명확히 표현하는 구조
- `with`, generator, comprehension을 목적에 맞게 절제해서 사용하는 방식
- 예외를 의미 있는 타입으로 변환하고 호출부가 처리 가능한 계약을 유지하는 구현
- 순수 로직과 I/O 경계를 분리해 테스트 가능한 구조
- 작은 함수와 명확한 이름으로 의도를 드러내는 코드

---

## 리뷰 시 핵심 질문

- 이 코드는 Python답게 단순하고 읽기 쉬운가?
- 타입과 데이터 구조가 도메인 의도를 충분히 드러내는가?
- 실패 시점에 원인과 책임이 명확하게 드러나는가?
- 테스트하기 쉬운 구조인가, 아니면 I/O와 상태에 강하게 결합되어 있는가?
