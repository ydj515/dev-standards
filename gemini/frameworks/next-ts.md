# Next.js + TypeScript Code Review Guidelines

이 문서는 Next.js(App Router 기준) + TypeScript 프로젝트에서 코드 리뷰 시 고려해야 할 가이드입니다.
목표는 **SSR/CSR 경계 명확화**, **성능**, **데이터 일관성**, **보안**, **유지보수성**을 동시에 확보하는 것입니다.

---

## 1. Server vs Client Component 경계

- Server Component를 기본값으로 사용하고 있는지 확인
- `"use client"`가 불필요하게 남용되지 않았는지 점검
- Client Component는 반드시 필요한 경우에만:
  - 브라우저 API 사용
  - 인터랙션
  - 상태/이벤트 핸들링
- Server Component에 클라이언트 전용 로직이 섞이지 않았는지 확인
- Client → Server 경계에서 불필요한 데이터 직렬화가 발생하지 않는지 검토

### 리뷰 질문

- 이 컴포넌트는 정말 client여야 하는가?
- server에서 해결 가능한 로직을 client로 밀어내지 않았는가?

---

## 2. Data Fetching 전략

- fetch 위치가 일관적인지 확인 (page/layout/server component 중심)
- 중복 fetch 발생 여부 점검
- Next.js 캐싱 전략을 이해하고 사용했는지 확인:
  - `cache: "force-cache"`
  - `cache: "no-store"`
  - `revalidate`
- 동일 데이터에 서로 다른 캐싱 정책이 섞여 있지 않은지 검토
- 서버 fetch vs 클라이언트 fetch 책임이 명확한지 확인

---

## 3. Rendering Strategy (SSR / SSG / ISR / CSR)

- 페이지 목적에 맞는 렌더링 전략을 선택했는지 검토
- SEO 필요한 페이지가 CSR로만 구성되지 않았는지 확인
- dynamic rendering이 의도된 것인지 점검
- 불필요한 hydration 비용 발생 여부 검토
- streaming/suspense가 필요한 구간인지 고려

---

## 4. Dynamic APIs & Rendering Opt-in

- `cookies()`, `headers()`, `searchParams`, `draftMode()` 사용이 의도적인지 확인
- 공용 layout이나 상위 segment에서 동적 API를 사용해 전체 하위 트리를 불필요하게 dynamic rendering으로 바꾸지 않았는지 점검
- 정적 페이지로 유지 가능한 화면이 request-time API 의존 때문에 캐싱 이점을 잃지 않는지 검토
- `notFound()`, `redirect()` 사용 위치가 데이터 흐름과 에러 처리 전략에 맞는지 확인

---

## 5. Layout & Routing Structure

- app router 구조가 도메인 단위로 정리되어 있는지 확인
- layout/page/loading/error 구조가 일관적인지 점검
- layout에 과도한 데이터 fetch/로직이 들어가 있지 않은지 검토
- route segment가 지나치게 깊어 복잡하지 않은지 확인
- 공통 UI가 중복 구현되지 않았는지 점검

---

## 6. Server Actions / Mutations

- Server Action이 진짜 서버 책임을 수행하는지 확인
- 민감 로직이 client에 노출되지 않았는지 점검
- mutation 이후 캐시 무효화 전략(`revalidatePath`, `revalidateTag`) 명확성
- optimistic UI가 필요한 경우 롤백 전략 존재 여부
- action 내부에서 인증/권한 체크가 누락되지 않았는지 확인

---

## 7. Environment & Secrets

- 비밀값이 client bundle로 노출되지 않는지 확인
- `NEXT_PUBLIC_` prefix 사용이 의도적인지 점검
- 서버 전용 환경변수를 client 코드에서 참조하지 않는지 확인
- `.env` 의존성이 문서화되어 있는지 검토

---

## 8. Performance & Bundle Size

- client component 크기가 과도하지 않은지 점검
- 불필요한 라이브러리가 client bundle에 포함되지 않았는지 확인
- dynamic import로 분리 가능한지 검토
- 이미지 최적화(`next/image`) 사용 여부
- font 최적화(next/font) 여부
- 큰 JSON/데이터를 client로 직접 넘기지 않았는지 점검

---

## 9. Caching & Revalidation

- 데이터 변경 시 stale 데이터가 남지 않는지 확인
- revalidation 전략이 명확한지 검토
- tag 기반 캐시 전략이 필요한지 고려
- 캐시 정책이 문서화되어 있는지 점검

---

## 10. Error Handling & Loading UX

- `error.tsx` / `loading.tsx`가 누락되지 않았는지 확인
- 서버 fetch 실패 시 graceful fallback 존재 여부
- 사용자에게 의미 있는 에러 메시지 제공 여부
- skeleton/loading UI 일관성 점검

---

## 11. Security

- server action / API route에서 입력 검증 여부
- 인증이 필요한 페이지가 보호되고 있는지 확인
- XSS 위험(`dangerouslySetInnerHTML`) 점검
- 쿠키/토큰 처리 방식이 안전한지 검토
- 민감 데이터가 로그에 출력되지 않는지 확인

---

## 12. API Routes / Route Handlers

- route handler가 domain 로직을 직접 포함하지 않는지 점검
- validation layer(zod 등) 존재 여부
- status code가 의미에 맞게 사용되는지 확인
- 에러 응답 형식이 일관적인지 검토

---

## 13. Accessibility & SEO

- `<head>` metadata 설정 여부
- semantic HTML 사용 여부
- 이미지 alt 누락 여부
- meta/og 태그 전략 일관성
- 접근성 기본 체크 통과 여부

---

## 14. Testing Strategy

- 서버 로직이 UI와 강하게 결합되지 않았는지 점검
- fetch/service layer가 테스트 가능 구조인지 확인
- server action 단위 테스트 가능 여부
- E2E 테스트가 필요한 핵심 흐름 식별

---

## 15. Next.js 안티패턴

- 상위 layout에서 무심코 `cookies()`나 `headers()`를 호출해 전체 트리를 dynamic으로 만드는 구조
- `"use client"`를 기본값처럼 남발해 server component 이점을 잃는 구현
- server action, route handler, client fetch가 같은 데이터를 각자 따로 다루는 중복 구조
- revalidation 전략 없이 mutation 후 우연히 최신 데이터가 보이길 기대하는 패턴
- 서버 전용 로직과 비밀값이 client bundle 경계로 새어 나가는 코드

---

## 16. Next.js 좋은 패턴

- server component를 기본값으로 두고 client component를 상호작용 경계로 제한하는 구조
- fetch 위치, 캐싱 전략, invalidation 정책이 문서화된 일관된 데이터 흐름
- route handler와 server action이 얇은 진입점 역할만 하고 도메인 로직은 별도 계층으로 분리된 설계
- loading, error, empty state와 SEO 메타데이터가 화면 책임에 맞게 함께 구성된 구현
- dynamic rendering이 필요한 지점을 명시적으로 제어하고 bundle/hydration 비용을 줄이는 방식

---

## 리뷰 시 핵심 질문

- 이 로직은 server에 있어야 하는가 client에 있어야 하는가?
- 캐싱 전략은 의도대로 동작하는가?
- hydration 비용은 최소화되었는가?
- 민감 데이터가 노출될 가능성은 없는가?
- 데이터 변경 시 UI가 일관되게 업데이트되는가?
