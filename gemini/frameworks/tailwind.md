# Tailwind CSS Code Review Guidelines

이 문서는 Tailwind CSS 기반 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.  
목표는 **일관된 디자인 토큰 사용**, **예측 가능한 클래스 조합**, **유지보수성**, **반응형 품질**을 함께 확보하는 것입니다.

---

## 1. Utility-First 경계 설정

- Tailwind 유틸리티는 **로컬 스타일 표현**에 집중하고, 비즈니스 로직을 className 조합에 숨기지 않는지 확인
- 단순 레이아웃과 시각 표현은 유틸리티로 처리하되, 동일한 class 조합이 반복되면 컴포넌트 추출 여부를 검토
- “재사용”을 이유로 너무 이른 추상화(`.btn-primary`, `.card-large` 같은 의미 불명확한 래퍼 클래스)만 늘어나지 않는지 점검
- 반대로 한 컴포넌트 안에 수십 개 유틸리티가 누적되어 읽기 어려워졌다면 역할 단위 분리 검토

---

## 2. Design Tokens & Theme 일관성

- 색상, 간격, 타이포그래피가 팀의 theme 설정 또는 CSS 변수에 맞게 사용되는지 확인
- 임의값(`w-[37px]`, `text-[#123456]`)이 반복된다면 토큰화 필요 여부를 검토
- breakpoint 사용이 일관적인지 확인 (`sm`, `md`, `lg` 기준이 뒤섞이지 않는지)
- 다크 모드, 브랜드 컬러, 상태 색상(success/error/warning)이 임시 값으로 흩어져 있지 않은지 점검

### 좋은 예: 토큰 기반 스타일

```tsx
function StatusBadge({ tone, children }: { tone: "success" | "warning"; children: React.ReactNode }) {
  const toneClass = {
    success: "bg-emerald-100 text-emerald-800",
    warning: "bg-amber-100 text-amber-800",
  }[tone];

  return (
    <span className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${toneClass}`}>
      {children}
    </span>
  );
}
```

---

## 3. Class Composition & 조건부 스타일링

- 문자열 이어붙이기보다 `clsx`, `classnames`, `cva` 등 팀 표준 방식으로 class 조합을 일관되게 관리하는지 확인
- 중첩 ternary가 길어져 어떤 상태에서 어떤 스타일이 적용되는지 읽기 어려워지지 않았는지 점검
- 충돌하는 유틸리티(`px-2 px-4`, `hidden flex`)가 의도 없이 함께 들어가 있지 않은지 확인
- 상태 스타일은 가능한 한 `disabled:`, `focus:`, `aria-*`, `data-*` 변형을 활용하고 있는지 검토

### 흔한 안티패턴

```tsx
<button
  className={`px-4 py-2 ${primary ? "bg-blue-500 text-white" : ""} ${danger ? "bg-red-500" : ""} ${
    disabled ? "opacity-50" : "hover:scale-105"
  } ${isMobile ? "w-full" : "w-auto"}`}
/>
```

- 상태 조합이 늘어날수록 충돌과 누락 가능성이 커짐

### 더 나은 패턴

```tsx
import clsx from "clsx";

function ActionButton({
  intent = "primary",
  disabled = false,
  block = false,
}: {
  intent?: "primary" | "danger";
  disabled?: boolean;
  block?: boolean;
}) {
  return (
    <button
      disabled={disabled}
      className={clsx(
        "inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition",
        intent === "primary" && "bg-slate-900 text-white hover:bg-slate-700",
        intent === "danger" && "bg-red-600 text-white hover:bg-red-500",
        disabled && "cursor-not-allowed opacity-50 hover:bg-inherit",
        block ? "w-full" : "w-auto",
      )}
    />
  );
}
```

---

## 4. Component 추출 기준

- 동일한 유틸리티 묶음이 3회 이상 반복되면 공통 컴포넌트 또는 helper 추출 후보로 봄
- 단, 추상화된 컴포넌트가 너무 많은 variant와 boolean props를 받아 오히려 사용법을 흐리지 않는지 점검
- Tailwind 클래스 재사용은 “의미 있는 UI 단위”로 묶는지 확인
- layout wrapper, section shell, button, badge, input 등 공통 UI의 기준이 일관적인지 검토

---

## 5. Responsive & State Variants

- 모바일 우선(mobile-first) 접근으로 작성되었는지 확인
- breakpoint별 스타일 변경이 누락되거나 충돌하지 않는지 점검
- hover 상태에만 의존하지 않고 keyboard focus, disabled, aria state가 함께 고려되었는지 확인
- `group`, `peer`, `data-*` 변형 사용 시 의도가 명확한지 검토

---

## 6. Accessibility

- 시맨틱 요소를 우선 사용하고 있는지 확인 (`button`, `a`, `label`)
- `focus-visible` 또는 동등한 포커스 스타일이 제거되지 않았는지 점검
- 상태 전달을 색상에만 의존하지 않는지 확인
- 텍스트 대비와 hit area가 충분한지 검토
- 화면 숨김 텍스트(`sr-only`)가 필요한 곳에 적절히 사용되는지 점검

---

## 7. Build Hygiene & Purge 안정성

- 동적 class 생성 방식 때문에 Tailwind가 실제 클래스를 탐지하지 못할 가능성이 없는지 확인
- 런타임 문자열 조합으로 임의의 class를 만들어 purge/safelist 문제를 만들지 않는지 점검
- 사용하지 않는 커스텀 유틸리티, 불필요한 plugin, 과도한 safelist가 누적되지 않았는지 검토

### 리뷰 질문

- className이 빌드 타임에 추론 가능한 구조인가?
- 동일한 스타일 패턴을 컴포넌트나 helper로 묶는 편이 더 명확하지 않은가?

---

## 8. Tailwind 안티패턴

- 임의값 남용으로 디자인 토큰이 사실상 무력화된 상태
- 한 줄 className에 모든 상태와 레이아웃을 몰아넣어 읽기 어려운 상태
- Tailwind와 별도 CSS 파일이 서로 같은 속성을 계속 덮어쓰는 구조
- `@apply`를 남용해 사실상 다른 CSS 프레임워크처럼 사용하는 패턴
- 동적 문자열 조합으로 purge 누락 위험이 있는 구현

---

## 9. Tailwind 좋은 패턴

- 토큰과 breakpoint 규칙을 theme 수준에서 관리하는 구조
- 반복되는 UI 패턴을 `Button`, `Input`, `Card` 같은 의미 있는 단위로 추출하는 방식
- class 조합 규칙을 helper 또는 variant utility로 정리한 구조
- `focus-visible`, `disabled`, `aria-*` 상태를 포함한 접근성 중심 스타일링

---

## 리뷰 시 핵심 질문

- 이 class 조합은 사람이 읽고 수정하기 쉬운가?
- 임의값보다 팀 공통 토큰을 사용할 수 없는가?
- 스타일 충돌 없이 상태와 반응형 요구사항이 명확히 표현되는가?
- Tailwind 사용이 UI 일관성을 강화하고 있는가, 아니면 예외를 늘리고 있는가?
