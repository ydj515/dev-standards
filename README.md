# dev-standards

이 저장소는 **여러 프로젝트에서 공통으로 사용하는 개발 표준과 LLM 컨텍스트를 중앙에서 관리**하기 위한 레포지토리입니다.

다른 프로젝트에서 이 레포지토리를 수정하지 않습니다. CI를 통해 필요한 문서를 가져와 자동 생성된 결과물만 커밋합니다.

## 목표

> 개발 표준이 추가될 때마다 목표는 추가되며, 규칙 변경 시 **모든 레포에 자동 반영 가능**한 구조 제공하는 것을 목표로 합니다.

1. LLM 기반 코드 리뷰의 일관성, 재현성 확보를 위한 gemini code review guidelines

## 준수사항

1. 표준에 대한 versioning을 합니다.
   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

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
   │  ├─ java.md
   │  ├─ python.md
   │  └─ typescript.md
   └─ frameworks/             # (선택) 프레임워크별 가이드
      ├─ spring.md
      ├─ django.md
      └─ nextjs.md
```