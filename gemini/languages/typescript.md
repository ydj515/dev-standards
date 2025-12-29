# TypeScript Code Review Guidelines

이 문서는 TypeScript 프로젝트에서 Gemini가 추가로 고려해야 할 규칙입니다.

---

## 1. Type Safety

- `any` 사용 여부 확인 및 대체 제안
- 명시적 Interface / Type Alias 사용 권장
- API 응답 타입 명확성 검토

---

## 2. Async / Await

- Promise 체이닝 대신 async/await 사용 여부
- 에러 핸들링 누락 여부 (`try/catch`) 확인

---

## 3. Readability

- 과도한 중첩 삼항 연산자 지양
- Destructuring을 통한 가독성 개선 제안