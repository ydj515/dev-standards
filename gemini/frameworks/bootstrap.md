# Bootstrap Code Review Guidelines

이 문서는 Bootstrap 기반 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.  
목표는 **일관된 레이아웃 시스템 사용**, **테마 확장 가능성**, **접근성**, **커스텀 CSS 통제**를 확보하는 것입니다.

---

## 1. Bootstrap 사용 경계

- Bootstrap을 선택했다면 grid, spacing, form, component 규칙을 일관되게 사용하는지 확인
- 한 화면 안에서 Bootstrap, 다른 CSS 프레임워크, 임의 커스텀 스타일이 충돌하지 않는지 점검
- 기본 컴포넌트 구조를 무시한 채 클래스만 일부 가져다 쓰며 DOM 구조가 깨지지 않는지 검토

### 리뷰 질문

- 이 화면은 Bootstrap의 설계 방식을 따르고 있는가?
- 커스텀 CSS가 Bootstrap의 기본 시스템을 보완하는 수준인가, 계속 덮어쓰는 수준인가?

---

## 2. Grid & Layout

- `container`, `row`, `col-*` 구조가 올바르게 사용되는지 확인
- grid 안에 또 다른 grid를 넣을 때 불필요한 중첩으로 복잡해지지 않는지 점검
- spacing은 우선 utility class(`mt-3`, `gap-2`, `px-4`)로 해결하고, 반복 패턴만 커스텀 CSS로 승격하는지 검토
- breakpoint별 column 구성과 stacking 동작이 의도대로 읽히는지 확인

### 흔한 안티패턴

```html
<div class="row">
  <div class="col-6" style="padding-right: 27px;">
    ...
  </div>
  <div class="col-6" style="margin-top: 13px;">
    ...
  </div>
</div>
```

- layout 규칙이 inline style에 흩어지면 반응형 유지보수가 어려워짐

---

## 3. Utility Class vs Custom CSS

- Bootstrap utility로 충분히 해결 가능한데 별도 CSS 파일에서 같은 속성을 다시 정의하지 않는지 확인
- 반복되는 예외 스타일만 의미 있는 컴포넌트 클래스로 추출하는지 점검
- `!important` 기반 override가 많다면 구조적 해결 대신 덮어쓰기만 누적되고 있는지 검토

### 좋은 패턴

```html
<section class="container py-4">
  <div class="d-flex align-items-center justify-content-between gap-3">
    <h1 class="h4 mb-0">주문 목록</h1>
    <button type="button" class="btn btn-primary">새 주문</button>
  </div>
</section>
```

---

## 4. Theme & Design Token 관리

- 브랜드 컬러, radius, spacing, typography 변경이 중앙 설정(Sass 변수, CSS 변수, theme layer)에서 관리되는지 확인
- 페이지별로 Bootstrap 내부 클래스를 직접 override하는 패턴이 반복되지 않는지 점검
- 동일한 버튼/폼/테이블이 화면마다 다른 모양으로 변형되지 않는지 검토

---

## 5. Component 구조와 시맨틱

- `btn`, `card`, `modal`, `navbar`, `form-control` 등 Bootstrap 컴포넌트가 권장 HTML 구조를 유지하는지 확인
- 스타일을 위해 `a.btn`를 버튼처럼 쓰면서 실제 동작은 form submit인 식의 시맨틱 불일치가 없는지 점검
- 링크와 버튼, 제목 계층, form label이 의미에 맞는 태그로 작성되었는지 검토

---

## 6. JavaScript Behavior 통합

- Modal, Dropdown, Collapse, Tooltip 같은 Bootstrap JS 컴포넌트 초기화 방식이 프로젝트 구조와 일관적인지 확인
- React/Vue 같은 프레임워크와 함께 쓸 때 DOM 직접 조작이 상태 관리와 충돌하지 않는지 점검
- `data-bs-*` 속성과 imperative API를 혼용하면서 lifecycle 문제가 생기지 않는지 검토

---

## 7. Accessibility

- 모달 열림/닫힘 시 focus 이동과 복귀가 적절한지 확인
- 드롭다운, 아코디언, 탭 UI가 keyboard navigation 가능한지 점검
- label, help text, error text가 폼 요소와 올바르게 연결되는지 확인
- 색상만으로 상태를 구분하지 않는지 검토

---

## 8. Performance & Asset 관리

- 필요한 Bootstrap CSS/JS만 포함할 수 있는 구조인지 검토
- 사용하지 않는 JS 플러그인까지 전부 로드하고 있지 않은지 점검
- 아이콘, 커스텀 테마, 별도 스크립트가 중복 다운로드되지 않는지 확인

---

## 9. Bootstrap 안티패턴

- layout 문제를 inline style과 `!important` override로만 해결하는 구조
- Bootstrap 클래스와 커스텀 CSS가 같은 속성을 계속 덮어쓰는 상태
- 시맨틱 태그 대신 전부 `div`로 조립된 UI
- 프레임워크 상태 관리와 Bootstrap JS 직접 조작이 충돌하는 구현
- 동일 컴포넌트가 페이지마다 조금씩 다른 규칙으로 재정의되는 상태

---

## 10. Bootstrap 좋은 패턴

- grid, spacing, form 규칙을 Bootstrap 기본 시스템 안에서 일관되게 사용하는 구조
- 브랜드 확장은 중앙 theme 설정에서 관리하고 화면별 예외를 줄이는 방식
- utility class로 빠르게 표현하되, 반복되는 조합만 공통 컴포넌트 클래스로 승격하는 접근
- 접근성과 시맨틱 HTML을 유지하면서 컴포넌트를 조립하는 구현

---

## 리뷰 시 핵심 질문

- 이 구현은 Bootstrap 기본 시스템을 활용하고 있는가, 아니면 계속 우회하고 있는가?
- 커스텀 CSS가 확장 역할을 하는가, 충돌 역할을 하는가?
- 반응형 레이아웃과 접근성 요구사항이 클래스 구조만 봐도 이해되는가?
- JS 컴포넌트 사용 방식이 현재 프레임워크 구조와 충돌하지 않는가?
