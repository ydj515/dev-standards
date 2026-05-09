# MUI Code Review Guidelines

이 문서는 MUI(Material UI) 기반 React 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.  
목표는 **theme 중심 설계**, **재사용 가능한 컴포넌트 조합**, **접근성**, **스타일 일관성**, **번들 관리**를 확보하는 것입니다.

---

## 1. Theme-First 접근

- 색상, spacing, typography, shape가 theme를 통해 일관되게 관리되는지 확인
- `sx`에 하드코딩된 `px`, `#hex`, 임의 z-index가 반복되면 theme token 승격 필요 여부를 검토
- 화면마다 비슷한 스타일을 각자 다르게 구현해 디자인 시스템이 약해지지 않는지 점검

### 좋은 패턴

```tsx
<Button
  variant="contained"
  sx={{
    px: 2.5,
    borderRadius: 2,
    textTransform: "none",
  }}
>
  저장
</Button>
```

- 단발성 보정은 `sx`로 처리하되, 반복되면 theme override 또는 공통 컴포넌트로 승격하는 것이 바람직함

---

## 2. Component Composition

- `Box`, `Stack`, `Grid`, `Paper` 조합이 역할에 맞게 사용되는지 확인
- 모든 것을 `Box`로만 감싸 DOM 깊이가 불필요하게 커지지 않는지 점검
- 공통 패턴은 `AppDialog`, `PageSection`, `FormCard` 같은 도메인/역할 기반 컴포넌트로 추출하는지 검토
- MUI 기본 컴포넌트를 래핑할 때 public API가 더 명확해지는지 확인

---

## 3. `sx`, `styled`, Theme Override 경계

- 일회성 로컬 스타일은 `sx`, 재사용 스타일은 `styled` 또는 theme override로 일관되게 구분하는지 확인
- 동일한 컴포넌트의 같은 스타일이 여러 파일에 복사되지 않는지 점검
- 전역 CSS override나 `.MuiButton-root` 직접 수정이 광범위하게 퍼져 있지 않은지 검토

### 흔한 안티패턴

```tsx
<TextField
  sx={{
    "& .MuiOutlinedInput-root": {
      height: "41px",
      background: "#fff",
      borderRadius: "3px",
    },
    "& .MuiInputLabel-root": {
      color: "#999",
      fontSize: "13px",
    },
  }}
/>
```

- 같은 override가 여러 곳에 반복되면 디자인 변경 비용이 급격히 커짐

---

## 4. Props API & Variant 설계

- 래핑 컴포넌트가 너무 많은 boolean prop을 받아 조합 폭발을 만들지 않는지 확인
- variant, size, color 같은 선택지를 명확히 제한하고 있는지 점검
- MUI 기본 props와 팀 커스텀 props의 책임이 섞이지 않는지 검토

---

## 5. Forms & Input 일관성

- `TextField`, `FormControl`, `FormHelperText`, `Select`, `Checkbox` 조합이 접근성 있게 구성되는지 확인
- 에러 상태, helper text, required 표시가 일관적인지 점검
- 폼 라이브러리(예: React Hook Form)와 연결 시 controlled/uncontrolled 전략이 일관적인지 검토

---

## 6. Accessibility

- Dialog, Menu, Popover, Tooltip 사용 시 aria 속성과 focus 관리가 자연스러운지 확인
- 아이콘 버튼에 accessible name(`aria-label`)이 있는지 점검
- 색상 대비, disabled 상태, keyboard navigation이 충분한지 검토
- MUI 기본 접근성을 커스텀 스타일이 깨뜨리지 않는지 확인

---

## 7. Performance & Bundle Size

- 무거운 컴포넌트(Data Grid, date picker, large icon set)를 필요한 범위에서만 로드하는지 검토
- import 방식이 프로젝트 전반에서 일관적인지 확인
- `sx` 객체와 inline render 로직이 지나치게 비대해져 컴포넌트 가독성을 해치지 않는지 점검
- 테이블, 리스트, 다이얼로그가 과도하게 중첩되어 렌더 비용이 커지지 않는지 확인

---

## 8. Styling Consistency & Global Override

- theme override와 로컬 override가 충돌하지 않는지 점검
- `CssBaseline`, typography scale, spacing 규칙이 화면마다 일관되게 적용되는지 확인
- 외부 CSS 프레임워크와 혼용하면서 우선순위 충돌이 생기지 않는지 검토

---

## 9. MUI 안티패턴

- 거의 모든 컴포넌트에 대형 `sx` 객체가 붙어 있는 상태
- 동일한 override가 여러 화면에 복사되어 있는 구조
- MUI 기본 접근성 동작을 커스텀 CSS로 깨뜨리는 패턴
- theme보다 하드코딩 값에 의존하는 스타일링
- 의미 없는 래퍼 컴포넌트가 과도하게 늘어나 기본 API보다 더 쓰기 어려운 상태

---

## 10. MUI 좋은 패턴

- theme token을 우선 사용하고, 반복 패턴은 override 또는 공통 컴포넌트로 끌어올리는 구조
- `sx`는 로컬 보정에, `styled`/theme는 재사용 규칙에 사용하는 명확한 기준
- Dialog, Form, Table 같은 공통 UI를 접근성까지 포함해 표준화한 방식
- MUI 기본 컴포넌트의 장점을 살리면서 도메인 요구사항만 얇게 래핑한 구현

---

## 리뷰 시 핵심 질문

- 이 스타일은 theme에 있어야 하는가, 로컬 `sx`에 있어야 하는가?
- 공통 UI 패턴이 MUI 기본 컴포넌트와 자연스럽게 결합되어 있는가?
- 접근성과 번들 크기를 해치지 않으면서 커스터마이징하고 있는가?
- 래핑 컴포넌트가 API를 단순화하고 있는가, 아니면 더 복잡하게 만들고 있는가?
