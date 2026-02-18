# TypeScript Code Review Guidelines

이 문서는 TypeScript 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 규칙을 정리한 가이드입니다.  
목표는 타입 안정성, 가독성, 유지보수성, 런타임 안전성을 동시에 확보하는 것입니다.

---

## 1. Type Safety

- `any` 사용 여부 확인 및 대체 제안 (`unknown`, generics, union type)
- `as` 타입 단언 남용 여부 검토 (런타임 검증 없이 강제 캐스팅 금지)
- 명시적 `interface` / `type alias` 정의 여부 확인
- API 응답 타입이 구조적으로 명확한지 검토
- 반환 타입이 암묵적으로 추론되는 경우, 공개 함수는 명시적 반환 타입 권장
- `never` 타입으로 도달 불가능 케이스를 표현할 수 있는지 검토
- discriminated union을 활용해 조건 분기를 타입 레벨에서 안전하게 만들 수 있는지 확인
- `enum` 대신 literal union 타입이 더 적합한지 검토

### 좋은 예

```ts
type Result =
  | { type: "success"; data: User }
  | { type: "error"; message: string };

function handle(result: Result) {
  switch (result.type) {
    case "success":
      return result.data;
    case "error":
      throw new Error(result.message);
    default:
      const _exhaustive: never = result;
      return _exhaustive;
  }
}
```

---

## 2. Null & Undefined Safety

- `strictNullChecks` 가정 하에 작성되었는지 확인
- `!` non-null assertion 남용 여부 점검
- optional chaining (`?.`)과 nullish coalescing (`??`) 활용 가능성 검토
- nullable 경계(API, DB, 외부 입력)가 명확한지 확인
- 함수 입력에서 nullable을 허용한다면 내부에서 즉시 정규화하는지 검토

### 권장 패턴

```ts
function normalizeName(name?: string): string {
  return name?.trim() ?? "unknown";
}
```

---

## 3. Async / Await & Error Handling

- Promise 체이닝 대신 `async/await` 사용 여부 검토
- `await` 누락으로 인한 unhandled Promise 여부 확인
- `try/catch`로 에러 경계가 명확한지 검토
- fire-and-forget async 호출이 의도된 것인지 확인
- 병렬 실행 가능한 작업을 순차 await 하고 있지 않은지 점검

### 개선 예

```ts
// ❌ 순차 실행
await fetchA();
await fetchB();

// ✅ 병렬 실행
await Promise.all([fetchA(), fetchB()]);
```

---

## 4. Readability & Maintainability

- 과도한 중첩 삼항 연산자 지양
- Destructuring을 통한 가독성 개선 제안
- 함수가 너무 많은 책임을 가지지 않는지 검토
- 매직 넘버/문자열을 상수로 추출할 수 있는지 확인
- Boolean 플래그 인자가 여러 개인 함수는 리팩토링 후보
- 의미 없는 축약 변수명 사용 지양

---

## 5. Functional Style & Immutability

- 불필요한 mutable 상태(`let`, 직접 push/pop) 사용 여부 점검
- `map`, `filter`, `reduce`, `flatMap` 활용 가능성 검토
- side-effect 없는 순수 함수로 분리 가능한지 확인
- 객체/배열을 직접 변이하지 않고 새로운 값 반환 가능성 검토

### 권장 패턴

```ts
const updated = users.map(u =>
  u.id === id ? { ...u, active: true } : u
);
```

---

## 6. API & Domain Modeling

- 도메인 개념이 타입으로 잘 표현되어 있는지 확인
- primitive obsession 여부 검토
- DTO와 Domain 모델이 구분되어 있는지 점검
- 외부 API 타입을 그대로 내부 로직에 퍼뜨리지 않는지 확인

### 예시

```ts
type UserId = string & { readonly brand: unique symbol };
```

---

## 7. Generics Usage

- generics가 불필요하게 복잡하지 않은지 확인
- 의미 없는 제약 제거
- 타입 추론이 가능한데 명시적 generic을 강제하지 않는지 점검
- 재사용 가능한 추상화를 generics로 표현 가능한지 검토

---

## 8. Module Structure & Dependency

- 순환 의존성 발생 여부 점검
- 내부 구현 세부사항이 외부로 노출되지 않는지 확인
- barrel export(`index.ts`)가 과도하게 커지지 않는지 검토
- domain / infra / ui 레이어 분리가 명확한지 확인

---

## 9. Performance & Runtime Considerations

- 불필요한 깊은 복사 사용 여부
- 대용량 배열에서 비효율적인 반복 구조 점검
- hot path에서 객체 생성이 과도하지 않은지 검토
- debounce/throttle이 필요한 곳인지 확인

---

## 10. Testing & Safety Nets

- public 함수에 대해 테스트 가능한 구조인지 검토
- 숨겨진 global state 의존 여부 점검
- deterministic하지 않은 코드가 추상화되어 있는지 확인
- 타입만 안전하고 런타임 검증이 없는 구조는 아닌지 점검

---

## 11. TypeScript vs JavaScript 경계

- JS 라이브러리 래핑 시 타입 정의가 정확한지 확인
- `@ts-ignore` 사용 사유가 정당한지 검토
- ambient declaration(`.d.ts`)이 실제 구현과 일치하는지 점검

---

## 12. Linting & Style Consistency

- eslint / prettier 규칙과 충돌하지 않는지 확인
- 팀 컨벤션 일관성 유지 여부 점검
- unused 변수/타입 제거

---

## 리뷰 시 핵심 질문

- 타입이 버그를 사전에 막고 있는가?
- 런타임에서 터질 수 있는 지점이 남아있는가?
- 읽는 사람이 의도를 바로 이해할 수 있는가?
- 확장 시 깨지지 않는 구조인가?