# 전역 스타일 및 공통 위젯 통합(리팩토링) 계획

웹 개발의 CSS 파일처럼, 앱 전체에 공통으로 들어가는 파란색 테마, 텍스트 크기, 그리고 여러 화면에서 똑같이 반복되는 '진척도 바(1단계-2단계-3단계)' 코드들을 하나의 파일로 모아 관리하기 위한 리팩토링(구조 개선) 계획입니다. 

## User Review Required

> [!IMPORTANT]
> 아래 계획을 검토하시고 **승인(진행해줘)** 해 주시면 바로 코딩을 시작합니다. 
> 승인해 주시면 이 내용은 `docs/07_style_refactoring_plan.md`로 백업됩니다!

## Proposed Changes

### [NEW] `lib/theme/app_colors.dart` (색상 전용 파일)
- 하드코딩된 모든 색상(`#0066FF`, `#E0E0E0` 등)을 이곳에 변수로 모읍니다.
- 예: `AppColors.primary`, `AppColors.textDark`, `AppColors.borderGray` 등으로 선언해 두고 전역에서 이 파일 하나만 불러와서 조작합니다.

### [NEW] `lib/theme/app_text_styles.dart` (폰트/글씨 전용 파일)
- 텍스트의 크기와 굵기를 묶어서 정의합니다.
- 예: 앱바 제목체, 일반 본문 텍스트, 하단 파란색 버튼용 굵은 글씨 등.

### [NEW] `lib/widgets/signup_stepper.dart` (공통 컴포넌트 분리)
- 1, 2, 3단계 화면마다 똑같이 복사+붙여넣기 되어있는 **스티퍼(상단 진척도 동그라미)** 코드를 떼어내어 하나의 부품(Widget) 파일로 독립시킵니다. 
- 각 화면에서는 딱 1줄(`SignupStepper(currentStep: 2)` 등)만 쓰면 렌더링되게 만듭니다.

### [MODIFY] `lib/main.dart` 
- 기본 뼈대인 테마(`ThemeData`) 설정을 좀 더 강화하여, 모든 앱바(`AppBar`)의 배경을 자동으로 흰색, 그림자를 없게 만들고 `Scaffold` 배경색을 기본 흰색으로 통일시킵니다.

### [MODIFY] 기존 모든 스크린 원본 수정
- `onboarding_screen.dart`
- `login_screen.dart`
- `signup_screen.dart`
- `signup_step2_screen.dart`
- `signup_step3_screen.dart`
=> 전체 파일을 돌며, 반복되던 색상 및 스타일 코드를 전부 지우고 위에서 만든 테마 변수들로 깔끔하게 교체합니다.

---

## Open Questions

- 특별히 확인하실 질문은 없으며, Flutter에서 웹의 CSS 역할을 완벽히 대체하기 위한 가장 모범적인(Best Practice) 구조인 `theme/` 적용 방식입니다.
- 앱 크기가 커질수록 색상 하나만 바꿀 때 `app_colors.dart` 한 줄만 수정하면 앱 전체가 바뀌게 되므로 유지보수성이 극대화됩니다!

## Verification Plan
- 터미널에서 전체 코드를 다루는 `flutter analyze`를 수행해 단 한번의 구문 오류도 없도록 만들겠습니다.
- 리팩토링 후 핫 리로드를 수행해 기존 구축해 놓았던 UI와 디자인 요소가 1px도 틀어지지 않고 똑같이 나오는지 확인합니다.
