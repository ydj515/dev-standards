# dev-standards

이 저장소는 **여러 프로젝트에서 공통으로 사용하는 개발 표준과 LLM 컨텍스트를 중앙에서 관리**하기 위한 레포지토리입니다.

다른 프로젝트에서 이 레포지토리를 수정하지 않습니다. CI를 통해 필요한 문서를 가져와 자동 생성된 결과물만 커밋합니다.

## ci-workflows와의 관계

이 저장소는 규칙의 **원본(Source of Truth)** 을 관리합니다.

실제 각 서비스 레포지토리에서는 이 저장소를 직접 수정하거나 복사하지 않고,
`ci-workflows` 저장소의 reusable workflow
`build-gemini-styleguide.yml`을 통해 필요한 문서를 가져옵니다.

흐름은 아래와 같습니다.

1. `dev-standards`에서 `gemini/base.md`, `gemini/languages/*.md`, `gemini/frameworks/*.md`를 관리합니다.
2. 변경 사항이 배포 가능한 상태가 되면 이 저장소에 버전 태그를 발행합니다.
3. 각 레포지토리는 `ci-workflows`의 reusable workflow를 실행합니다.
4. workflow는 `styleguide.yml` 설정을 읽고, 이 저장소의 특정 태그(`standards_ref`)에서 문서를 가져와 `.gemini/styleguide.md`를 조합합니다.

즉, 규칙 변경은 이 저장소에서 관리하고, 실제 배포/동기화는 `ci-workflows`가 담당합니다.

## 목표

> 개발 표준이 추가될 때마다 목표는 추가되며, 규칙 변경 시 **모든 레포에 자동 반영 가능**한 구조 제공하는 것을 목표로 합니다.

1. LLM 기반 코드 리뷰의 일관성, 재현성 확보를 위한 gemini code review guidelines

## 준수사항

1. 표준에 대한 versioning을 합니다.
   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. 소비 레포지토리는 보통 `ci-workflows`를 통해 이 저장소의 특정 태그를 참조합니다.
   - `ci-workflows`의 workflow 버전과
   - `dev-standards`의 `standards_ref` 버전이
   함께 어떤 규칙이 배포되는지를 결정합니다.

## 1. gemini code review guidelines

여러 repository의 gemini code review guide 파일(`.gemini/styleguide.md`, `.gemini/config.yaml`)을 관리합니다.

### 구조

규칙은 아래의 구조로 구성됩니다.

1. Base – 언어와 무관한 공통 사고방식과 리뷰 원칙
2. Language – 언어별 문법, 관용적 표현, 주의사항
3. Framework (Optional) – 프레임워크 특화 규칙

규칙은 상속(inheritance) 이 아니라 조합(composition) 됩니다.

```text
dev-standards/
└─ gemini/
   ├─ base.md                 # 모든 프로젝트 공통 규칙
   ├─ languages/              # 언어별 가이드
   │  ├─ go.md
   │  ├─ java.md
   │  ├─ kotlin.md
   │  ├─ python.md
   │  └─ typescript.md
   └─ frameworks/             # (선택) 프레임워크별 가이드
      ├─ bootstrap.md
      ├─ fastapi.md
      ├─ mui.md
      ├─ next-ts.md
      ├─ react-ts.md
      ├─ spring.md
      ├─ tailwind.md
      └─ thymeleaf.md
```
