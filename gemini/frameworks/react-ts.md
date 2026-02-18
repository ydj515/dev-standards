# React + TypeScript Code Review Guidelines

이 문서는 React(주로 함수형 컴포넌트) + TypeScript 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 규칙을 정리한 가이드입니다.  
목표는 **예측 가능한 상태 관리**, **렌더 성능**, **접근성**, **테스트 용이성**, **타입 안정성**을 함께 확보하는 것입니다.

---

## 1. Component Design & Responsibility

- 컴포넌트가 한 가지 책임을 가지는지 확인 (UI / 로직 / 데이터 분리)
- 200~300줄 이상 커지는 컴포넌트는 분리 후보
- “재사용”을 위해 오히려 복잡해진 추상화는 지양 (과한 범용화)
- Container/Presentational(또는 Page/Feature/UI) 레이어가 일관되게 나뉘어 있는지 확인
- props drilling이 깊어지는 경우, Context/상태관리/컴포넌트 구조 재설계를 검토

---

## 2. Props & Type Modeling (React에서 특히 중요)

- `any` 금지. props 타입을 명확히 정의
- 컴포넌트 public API(props)는 **좁고 명확하게**
- boolean 플래그 props가 늘어날수록 조합 폭발 → discriminated union 검토
- 콜백 props의 시그니처가 명확한지 확인 (`(value: T) => void`)
- DOM 이벤트 타입을 정확히 사용 (`React.ChangeEvent<HTMLInputElement>` 등)
- `children` 타입은 의도에 맞게:
  - 일반적인 슬롯: `React.ReactNode`
  - “단일 엘리먼트만 허용” 같은 제약이 있으면 더 좁게 모델링

### 좋은 예: 플래그 폭발 방지

```ts
type ModalProps =
  | { kind: "confirm"; onConfirm: () => void; onCancel: () => void }
  | { kind: "info"; onClose: () => void };

function Modal(props: ModalProps) {
  // kind로 분기하면 타입이 안전하게 좁혀짐
}
```

---

## 3. State Management (Local vs Global)

- state는 “최소한”만 유지하고, 나머지는 derived value로 계산 가능한지 확인
- state가 서로 강하게 결합되어 있다면 객체로 묶거나 reducer 검토
- 전역 상태 도입(예: Zustand/Redux)은 “진짜 공유가 필요한 경우”에만
- Form state는 라이브러리(React Hook Form 등) 쓰는 편이 더 안정적일 수 있음 (팀 정책에 따름)
- Server state(캐시/동기화)는 React Query/SWR 같은 도구를 고려 (있다면 규칙 준수)

---

## 4. Hooks Rules & Correctness

- Hook 호출 규칙 준수 (조건문/루프 내부 호출 금지)
- custom hook으로 로직을 추출할 때:
  - UI 없는 순수 로직이면 hook보다 plain function이 나을 수 있음
  - hook이 너무 많은 상태/부수효과를 갖지 않는지 확인
- `useEffect`는 “마지막 수단”에 가깝게:
  - 파생값 계산을 effect로 하지 말고 렌더에서 계산(또는 `useMemo`) 검토
- dependency array가 정확한지 점검
  - 누락으로 stale closure 발생 여부
  - 과도한 의존성으로 무한 루프/불필요 re-run 여부
- `useRef`를 “렌더에 영향 없는 값” 저장용으로만 쓰는지 확인

---

## 5. Effects & Side Effects (의도 명확성)

- `useEffect` 안에서 비동기 처리 시 취소/무시 전략이 있는지 확인
  - 요청 경쟁(race condition) 발생 가능성 점검
- effect 안에서 state를 세팅할 때 조건이 명확한지 확인 (무한 업데이트 방지)
- cleanup 필요 여부 점검 (이벤트 리스너, interval, subscription)

### 흔한 개선: async effect 패턴

```ts
useEffect(() => {
  let ignore = false;

  (async () => {
    const data = await fetchSomething();
    if (!ignore) setState(data);
  })();

  return () => {
    ignore = true;
  };
}, []);
```

---

## 6. Performance & Rendering

- 불필요한 re-render 유발 여부 점검
  - props로 내려가는 객체/함수 매 렌더마다 새로 생성되는지
- `useMemo` / `useCallback`은 “필요할 때만”
  - 남발하면 복잡도만 증가
  - 하지만 리스트 렌더, heavy compute, memoized child에는 효과적
- 리스트 렌더에서 `key`가 안정적인지 확인 (index key 지양)
- 큰 리스트는 가상화(react-window 등) 필요 여부 검토
- 상태 업데이트는 batching/불변성을 유지하는지 확인

---

## 7. Forms & Controlled/Uncontrolled

- controlled input은 값/핸들러가 명확한지 확인
- 숫자/날짜 입력의 파싱/검증 전략이 일관적인지 점검
- 검증 로직이 UI 컴포넌트에 과도하게 섞이지 않았는지 확인
- submit 시 중복 클릭/중복 요청 방지 처리

---

## 8. Data Fetching & Error/Loading UX

- 로딩/에러/빈 상태(empty state) UI가 빠지지 않았는지 확인
- API 호출이 컴포넌트 곳곳에 흩어져 있지 않은지(추상화/훅/서비스 레이어)
- 에러 메시지가 사용자 친화적인지, 디버그 정보와 분리되어 있는지
- optimistic update / retry / cancel 정책이 필요한지 검토
- SSR/SSG 환경(Next.js 등)에서는 fetch 위치와 캐싱 전략이 일관적인지 확인

---

## 9. Accessibility (A11y) — 기본 체크리스트

- 클릭 가능한 요소에 `button` 사용 여부 (`div onClick` 지양)
- `aria-label`, `role`, `tabIndex`가 올바른지 확인
- 폼 요소에 label 연결 (`<label htmlFor=...>`)
- focus 관리(모달/다이얼로그 열고 닫을 때) 고려
- 색상만으로 상태를 전달하지 않는지 확인
- 이미지 alt 텍스트의 적절성

---

## 10. Styling & UI Consistency

- 스타일 방식(Tailwind/CSS Modules/styled-components 등)이 일관적인지 확인
- 컴포넌트별 className이 과도하게 길어져 유지보수성이 떨어지지 않는지 점검
- 재사용 가능한 UI 컴포넌트(Button/Input/Modal)는 단일 소스로 관리되는지 확인
- 반응형/다크모드 등 프로젝트 요구사항에 맞게 구현되었는지 확인

---

## 11. Security (UI 관점)

- 사용자 입력을 그대로 `dangerouslySetInnerHTML`로 렌더링하는지 점검 (가능하면 금지)
- 외부 링크 `target="_blank"` 시 `rel="noreferrer noopener"` 확인
- 민감 데이터(토큰 등)를 localStorage에 저장하는 경우 위험성 인지 및 대안 검토(프로젝트 정책)
- 에러 로그에 PII(개인정보)가 포함되지 않도록 주의

---

## 12. Testing & Storybook

- 핵심 로직이 컴포넌트 내부에 숨겨져 테스트가 어려운 구조인지 점검
- UI 컴포넌트는 Storybook/스냅샷보다 “행동 기반 테스트”를 우선 고려
- 비동기 UI는 로딩/성공/실패/빈 상태 테스트가 있는지 확인
- mock이 과도하게 구현 디테일에 결합되어 있지 않은지 점검

---

## 13. React + TS 자주 나오는 타입 실수 체크

- 이벤트 타입을 `any`로 뭉개지 않았는지 확인
- `setState`에 함수형 업데이트가 필요한 상황(이전 state 기반)인지 점검
- `React.FC` 강제 사용은 팀 정책에 따르되, 암묵적 children 포함 여부를 인지
- `as unknown as ...` 같은 이중 단언은 마지막 수단 (대부분 설계/런타임 검증 문제)
- `useState([])` 초기값 때문에 `never[]`/`any[]`로 추론되지 않도록 제네릭 부여 필요 여부 확인

---

## 리뷰 시 핵심 질문

- 이 컴포넌트는 “왜” 다시 렌더링되는가? 불필요한 렌더는 없는가?
- side effect는 의도대로만 실행되는가? dependency는 정확한가?
- 로딩/에러/빈 상태가 빠지지 않았는가?
- 접근성이 기본 수준을 충족하는가?
- props 타입이 “사용법을 강제”할 만큼 명확한가?