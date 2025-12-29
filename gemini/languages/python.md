# Python Code Review Guidelines

이 문서는 Python 프로젝트에서 Gemini가 추가로 고려해야 할 규칙입니다.

---

## 1. Pythonic Code

- List / Dict Comprehension 활용 가능성 검토
- 불필요한 반복문 및 임시 변수 제거 제안
- Context Manager(`with`) 사용 여부 확인

---

## 2. Type Hinting

- 공개 함수 및 복잡한 로직에 Type Hint 누락 여부 확인
- `Optional`, `Union` 사용 적절성 검토
- mypy 등 정적 분석 도구 활용 가능성 제안

---

## 3. Error Handling

- 광범위한 `except Exception` 사용 지양
- 의미 있는 예외 타입 분리 제안