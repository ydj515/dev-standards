# Thymeleaf Code Review Guidelines

이 문서는 Thymeleaf 기반 서버 사이드 렌더링 프로젝트에서 코드 리뷰 시 추가로 고려해야 할 가이드입니다.  
목표는 **템플릿 책임 분리**, **안전한 렌더링**, **재사용 가능한 뷰 구조**, **컨트롤러-뷰 계약의 명확성**을 확보하는 것입니다.

---

## 1. Template Responsibility

- 템플릿은 **표현(presentation)** 에 집중하고, 복잡한 비즈니스 판단은 Controller/Service에서 끝내는지 확인
- 조건문과 반복문이 많더라도 “보여주는 규칙” 수준을 넘어서 계산 로직까지 포함하지 않는지 점검
- 템플릿 안에서 복잡한 문자열 조립, 상태 계산, 권한 분기를 과도하게 수행하면 ViewModel 정리 필요 여부를 검토

### 리뷰 질문

- 이 로직은 템플릿에서 판단해야 하는가, 아니면 컨트롤러가 준비해야 하는가?
- 화면을 그리기 위한 최소한의 데이터만 모델에 실려 오는가?

---

## 2. Controller-Template 계약

- `Model`에 전달되는 값이 명확한 이름과 구조를 가지는지 확인
- Entity를 그대로 템플릿에 전달해 화면이 영속성 구조에 결합되지 않았는지 점검
- 템플릿이 `${order.customer.address.zipCode}` 같은 깊은 탐색에 의존하지 않는지 확인
- null 가능성이 높은 값은 Controller에서 가공하거나 명시적으로 처리하는지 검토

### 좋은 패턴

```java
public record OrderSummaryView(
    String orderNumber,
    String customerName,
    String statusLabel,
    BigDecimal totalPrice
) {}
```

- 템플릿이 필요한 값만 전달하면 화면 로직이 단순해지고 변경 영향 범위가 줄어듦

---

## 3. Fragment & Layout 재사용

- 헤더, 푸터, 페이징, 폼 필드, 테이블 row 등 반복 마크업이 fragment로 정리되어 있는지 확인
- 공통 레이아웃이 복사-붙여넣기 형태로 중복되지 않는지 점검
- fragment가 너무 범용적이어서 입력 파라미터가 과도하게 많아지지 않는지 검토

### 좋은 예: 공통 fragment 활용

```html
<div th:replace="~{fragments/form :: inputField(
  id='email',
  label='이메일',
  field=*{email},
  error=${#fields.hasErrors('email')}
)}"></div>
```

---

## 4. Escaping & XSS 방어

- 사용자 입력이나 외부 데이터를 출력할 때 기본적으로 escape되는 `th:text`를 사용하는지 확인
- `th:utext`는 신뢰 가능한 HTML만 렌더링하는 매우 제한된 경우에만 허용하는지 점검
- HTML 조각을 그대로 출력해야 한다면 sanitize 여부와 데이터 출처가 분명한지 검토
- URL 생성 시 문자열 이어붙이기보다 `@{...}` 구문을 사용하는지 확인

### 흔한 안티패턴

```html
<div th:utext="${comment.content}"></div>
```

- 댓글, 게시글 본문 등 사용자 입력에 `th:utext`를 바로 적용하면 XSS 위험이 커짐

---

## 5. Form Binding & Validation

- 폼은 `th:object`, `th:field` 중심으로 일관되게 바인딩되는지 확인
- 검증 에러 메시지가 필드와 자연스럽게 연결되는지 점검
- `selected`, `checked`, `value`를 수동 문자열 비교로 처리하지 않는지 검토
- CSRF 토큰, method override, validation message가 프레임워크 관례에 맞게 적용되는지 확인

### 더 나은 패턴

```html
<form th:action="@{/members}" th:object="${memberForm}" method="post">
  <input type="text" th:field="*{name}" />
  <p th:if="${#fields.hasErrors('name')}" th:errors="*{name}"></p>
</form>
```

---

## 6. Conditional Rendering & Iteration

- `th:if`, `th:unless`, `th:switch` 사용이 읽기 쉬운 수준인지 확인
- 중첩 조건이 많다면 Controller에서 표시용 flag나 enum label을 준비하는 편이 더 나은지 검토
- 반복문 내부에서 다시 복잡한 분기를 수행해 템플릿 가독성이 무너지지 않는지 점검
- 빈 목록, 권한 없음, 조회 실패 같은 상태가 템플릿에서 명확히 드러나는지 확인

---

## 7. Internationalization & Formatting

- 사용자 노출 문자열이 message bundle로 분리되어 있는지 확인
- 날짜, 숫자, 통화 포맷이 locale 요구사항에 맞게 처리되는지 점검
- 텍스트를 하드코딩해 다국어 대응이 어려워지지 않는지 검토

---

## 8. URL & Navigation 처리

- 링크와 form action이 `@{...}` 문법으로 안전하게 생성되는지 확인
- path variable, query parameter가 수동 문자열 결합으로 작성되지 않는지 점검
- 현재 페이지 상태(정렬, 필터, 페이지네이션)가 URL에 일관되게 반영되는지 검토

---

## 9. Thymeleaf 안티패턴

- 템플릿 안에서 복잡한 계산과 분기 로직을 처리하는 구조
- Entity를 그대로 노출해서 화면이 도메인 모델에 강하게 결합된 상태
- 사용자 입력을 `th:utext`로 직접 렌더링하는 패턴
- fragment 없이 공통 마크업이 여러 파일에 복사된 구조
- 폼 바인딩을 수동 문자열 비교로 구현해 검증/유지보수가 어려운 상태

---

## 10. Thymeleaf 좋은 패턴

- Controller가 화면 전용 DTO/ViewModel을 준비하는 구조
- 재사용 가능한 fragment와 명확한 레이아웃 구성을 갖춘 템플릿
- `th:text`, `th:field`, `th:errors`, `@{...}` 등 표준 표현식을 일관되게 사용하는 방식
- 빈 상태, 에러 상태, 권한 상태를 화면에 명시적으로 표현하는 구현

---

## 리뷰 시 핵심 질문

- 템플릿이 표현 책임에만 머무르고 있는가?
- 컨트롤러가 화면에 필요한 데이터를 충분히 가공해서 전달하는가?
- escape, URL 생성, form binding이 프레임워크의 안전한 기본 경로를 따르는가?
- 공통 마크업과 상태 처리가 유지보수 가능한 구조인가?
