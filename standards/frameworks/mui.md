# MUI Guidelines & Standards

MUI 코드는 component마다 임의의 CSS를 얹는 방식이 아니라 theme token, component API와
slot composition을 통해 일관된 design system을 확장해야 합니다. styling 방법은 영향
범위에 따라 one-off, reusable component, theme override 순서로 선택합니다.

## 1. MUI다운 기본 원칙

- color, typography, spacing, radius와 breakpoint를 theme에 정의하고 component에서 raw
  값의 반복을 줄입니다.
- `ThemeProvider`는 application 경계에 두고 nested theme는 명확한 product 영역이나
  color scheme처럼 제한된 경우에만 사용합니다.
- MUI component가 제공하는 semantic prop, variant, size, color와 state class를 먼저
  사용하고 내부 DOM 구조를 직접 추측하지 않습니다.
- 반복되는 product UI는 MUI primitive를 감싼 project component로 만들고 business
  화면에서 MUI 세부 설정을 반복하지 않습니다.

## 2. 권장 아키텍처

MUI를 application 화면에서 직접 반복 설정하기보다 theme, product UI component와
feature 화면의 세 층으로 구성합니다. 공용 UI는 domain을 모르고 feature가 label,
권한과 business state를 결합합니다.

```text
src/
├─ app/providers/ThemeProvider.tsx
├─ design-system/
│  ├─ theme/
│  │  ├─ tokens.ts
│  │  ├─ component-overrides.ts
│  │  └─ index.ts
│  └─ components/               # ProductButton, ProductDialog, FormField
├─ features/orders/ui/          # OrderForm, OrderStatusChip
└─ pages/                       # feature 화면 조립
```

- 의존 방향은 `pages/features → design-system → MUI`입니다. design system이 feature
  model이나 API type을 참조하지 않습니다.
- token은 브랜드 의미를, theme override는 전역 MUI 기본값을, wrapper component는 반복되는
  product 계약을 소유합니다. 화면 한 곳의 예외는 가까운 `sx`에 둡니다.
- 여러 application이 공유하지 않는 프로젝트라면 별도 package부터 만들지 않고 위 경계를
  같은 source tree에서 유지합니다.

```tsx
import type { PropsWithChildren } from "react";
import { createTheme, ThemeProvider } from "@mui/material/styles";

const appTheme = createTheme({
  palette: { primary: { main: "#0057b8" } },
  shape: { borderRadius: 8 },
});

export function AppThemeProvider({ children }: PropsWithChildren) {
  return <ThemeProvider theme={appTheme}>{children}</ThemeProvider>;
}
```

provider는 application 조립 경계에 한 번 두고 feature component는 동일 theme contract를
소비합니다.

## 3. Styling 선택 기준

- 한 instance의 작은 조정은 `sx`를 사용합니다.
- 여러 위치에서 재사용되고 자체 API가 필요한 style은 `styled()` 또는 wrapper
  component로 승격합니다.
- 전체 product에서 같은 MUI component의 기본값과 variant를 바꾸면 theme의
  `components` defaultProps/styleOverrides/variants로 관리합니다.
- global CSS override는 마지막 수단으로 사용하고 불안정한 generated class selector에
  의존하지 않습니다.
- `sx` object를 매 render 무의미하게 크게 만들거나 모든 layout을 theme override로
  올리지 않습니다.

```tsx
const theme = createTheme({
  components: {
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: { root: { textTransform: "none" } },
    },
  },
});
```

## 4. Component와 slot composition

- 내부 slot 변경은 공식 `slots`와 `slotProps` API를 사용합니다. descendant selector로
  구현 세부를 깊게 따라가지 않습니다.
- wrapper component는 원래 component의 접근성 prop, event, ref와 polymorphic 동작을
  보존합니다.
- boolean prop이 늘어나면 project variant 또는 분리된 component로 유효 조합을
  제한합니다.
- theme module augmentation은 한 위치에서 관리하고 모든 화면이 별도 declaration을
  추가하지 않게 합니다.

## 5. Layout과 responsive UI

- `Stack`, `Box`, `Grid`, Container의 책임을 구분하고 같은 축의 간격을 margin 조합보다
  `gap`/`spacing`으로 표현합니다.
- breakpoint 값은 theme를 사용하고 임의 media query를 component마다 반복하지 않습니다.
- responsive prop과 `sx` breakpoint object가 생성하는 실제 DOM/CSS를 mobile과 desktop
  viewport에서 확인합니다.
- Dialog, Drawer, Menu와 Popover는 viewport overflow, focus trap과 portal container를
  함께 검증합니다.

## 6. Form과 접근성

- `TextField` 편의 API와 조합형 input을 필요에 맞게 선택하고 label, helper text,
  error와 required 상태를 연결합니다.
- icon-only button에는 accessible name을 제공합니다.
- Tooltip을 button name의 유일한 근거로 사용하지 않습니다.
- theme customization 뒤에도 focus visible, disabled, error, hover와 contrast 상태를
  확인합니다.

## 7. 성능과 dependency

- package의 public import path를 사용하고 내부 deep import에 의존하지 않습니다.
- icon package 전체나 무거운 lab component가 bundle에 포함되지 않는지 build 결과로
  확인합니다.
- style 문제를 해결하기 위해 provider를 component마다 중첩하거나 theme를 매 render
  재생성하지 않습니다.
- server rendering 프로젝트는 style engine setup과 hydration 순서를 공식 integration에
  맞춥니다.

## 8. 테스트

- generated class name보다 role, accessible name, visible state와 사용자 interaction을
  검증합니다.
- theme variant, dark/light scheme, responsive overflow, keyboard navigation을 포함합니다.

## 9. MUI 안티패턴

- raw color/spacing 반복과 `!important` 누적
- generated class와 내부 DOM descendant selector 의존
- 접근성 prop과 ref를 버리는 wrapper component
- 매 render theme 생성 또는 모든 변경을 global override로 해결

참고: [MUI Theming](https://mui.com/material-ui/customization/theming/),
[How to customize](https://mui.com/material-ui/customization/how-to-customize/),
[Themed components](https://mui.com/material-ui/customization/theme-components/),
[Building extensible themes](https://mui.com/material-ui/guides/building-extensible-themes/)
