# Go Code Review Guidelines

이 문서는 Go 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 규칙을 정리한 가이드입니다.
목표는 **명확한 에러 처리**, **작고 단순한 인터페이스**, **동시성 안전성**, **예측 가능한 패키지 구조**를 확보하는 것입니다.

---

## 1. Idiomatic Go

- Go다운 단순한 제어 흐름과 명명 규칙을 따르는지 확인
- 불필요하게 OOP 스타일 추상화, getter/setter, 계층을 늘리지 않는지 점검
- 짧은 함수와 명확한 이름으로 의도를 드러내는지 검토
- “영리한 코드”보다 읽기 쉬운 코드가 우선인지 확인

### 리뷰 질문

- 이 구현은 Go 관용구에 맞는가?
- 더 단순한 표준 라이브러리 조합으로 표현할 수 없는가?

---

## 2. Error Handling

- 에러를 무시하지 않고 즉시 처리하거나 상위로 전달하는지 확인
- `fmt.Errorf("...: %w", err)`로 원인을 보존하는지 검토
- panic은 truly unrecoverable 상황에만 사용되는지 점검
- sentinel error, typed error, wrapping 전략이 일관적인지 확인

### 좋은 예

```go
user, err := repo.FindByID(ctx, id)
if err != nil {
	return User{}, fmt.Errorf("find user by id %d: %w", id, err)
}
```

---

## 3. Interface Design

- 인터페이스가 소비자 측에 작게 정의되어 있는지 확인
- 구현체가 하나뿐인데 조기 추상화로 인터페이스를 남발하지 않는지 점검
- `interface{}` 또는 `any`로 타입 정보를 잃고 있지 않은지 검토
- 메서드 집합이 역할 단위로 응집되어 있는지 확인

### 흔한 안티패턴

```go
type UserService interface {
	Create(ctx context.Context, req CreateUserRequest) (User, error)
	Update(ctx context.Context, id int64, req UpdateUserRequest) (User, error)
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, filter UserFilter) ([]User, error)
}
```

- 소비자 입장에서 필요한 일부 기능만 쓰는데도 거대한 인터페이스에 결합될 수 있음

---

## 4. Context 사용

- 요청 범위 작업에 `context.Context`가 올바르게 전달되는지 확인
- context를 struct field에 저장하지 않는지 점검
- 취소, timeout, deadline이 필요한 I/O 경계에 반영되는지 검토
- context 값 사용이 최소화되고, 타입 안전한 key 규칙을 따르는지 확인

---

## 5. Concurrency & Goroutine Safety

- goroutine 생성이 lifecycle과 종료 조건을 가지는지 확인
- 공유 상태 접근 시 mutex, channel, ownership 규칙이 명확한지 점검
- loop variable capture 문제 가능성이 없는지 검토
- goroutine leak, channel deadlock, unbounded fan-out 위험이 없는지 확인

### 흔한 안티패턴

```go
for _, job := range jobs {
	go func() {
		process(job)
	}()
}
```

- 반복 변수 캡처로 의도와 다른 값이 처리될 수 있음

### 더 나은 패턴

```go
for _, job := range jobs {
	job := job
	go func() {
		process(job)
	}()
}
```

---

## 6. Data Structures & Memory

- 슬라이스/맵 초기 용량을 예측 가능한 경우 적절히 지정하는지 검토
- 큰 구조체를 값/포인터 중 어떤 방식으로 다루는지가 일관적인지 확인
- 불필요한 복사, append 남용, 메모리 유지(retention) 문제가 없는지 점검
- zero value가 안전하게 동작하도록 타입을 설계했는지 검토

---

## 7. Package Structure & Visibility

- 패키지가 도메인 책임 단위로 나뉘어 있는지 확인
- export가 정말 필요한 식별자만 공개하는지 점검
- `internal` 패키지 활용이 적절한지 검토
- 패키지명이 너무 일반적(`util`, `common`, `base`)이지 않은지 확인

---

## 8. HTTP / I/O / Resource Handling

- `resp.Body.Close()` 같은 리소스 정리가 누락되지 않았는지 확인
- HTTP handler에서 파싱, 검증, 도메인 로직, 응답 변환 책임이 뒤섞이지 않는지 점검
- 외부 호출의 timeout, retry, status code 처리 전략이 명확한지 검토
- 입력 검증과 출력 인코딩이 안전하게 처리되는지 확인

---

## 9. Testing

- table-driven test로 다양한 케이스를 명확히 표현할 수 있는지 검토
- 외부 의존성(DB, HTTP, clock)을 테스트 가능한 경계로 분리했는지 확인
- race condition 가능성이 있는 코드가 테스트 전략에 반영되는지 점검
- public behavior 중심 테스트인지, 내부 구현에 과도하게 결합된 테스트인지 검토

---

## 10. Logging & Observability

- 에러를 반환하면서 같은 에러를 중복 로깅하지 않는지 확인
- request id, user id 같은 진단 정보가 필요한 지점에 포함되는지 검토
- 민감한 정보가 로그에 남지 않는지 점검
- 구조화 로그를 쓰는 프로젝트라면 형식 일관성이 유지되는지 확인

---

## 11. Go 안티패턴

- 의미 없는 거대 인터페이스와 조기 추상화
- 에러를 무시하거나 문자열만 던져 원인 체인이 끊기는 패턴
- goroutine을 시작만 하고 종료/취소 전략이 없는 구조
- `context.Context`를 struct field에 저장하거나 optional parameter처럼 사용하는 방식
- `util` 패키지에 로직이 계속 쌓여 패키지 경계가 흐려지는 상태

---

## 12. Go 좋은 패턴

- 작은 인터페이스와 명확한 concrete type 중심 설계
- `%w`를 활용한 일관된 에러 전파와 문맥 보존
- context, timeout, cancellation을 I/O 경계에 자연스럽게 반영하는 구조
- table-driven test와 명확한 패키지 경계로 유지보수성을 높인 구현
- 채널, mutex, goroutine의 소유권과 종료 전략이 분명한 동시성 코드

---

## 리뷰 시 핵심 질문

- 이 코드는 Go답게 단순하고 직접적인가?
- 에러와 context가 호출 경계를 따라 일관되게 전달되는가?
- 동시성 코드가 안전하게 종료되고 디버깅 가능한 구조인가?
- 인터페이스와 패키지 경계가 미래 확장을 돕는가, 아니면 과한 추상화인가?
