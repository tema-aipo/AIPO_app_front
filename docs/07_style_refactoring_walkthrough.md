# UI 구조 개선(디자인 시스템 적용) 완료

지저분했던 코드들을 완전히 걷어내고, 깔끔한 베테랑 개발자의 템플릿(CSS 구조)으로 리팩토링을 완료했습니다! 이번 작업 내역은 `docs/07_style_refactoring_walkthrough.md`로 백업됩니다.

## 1. 2가지 핵심 테마 파일 생성
- `lib/theme/app_colors.dart`: `AppColors.primary`, `AppColors.textDark`처럼 변수 하나로 앱 내 모든 색상을 통제하게 만들었습니다. 만약 나중에 "우리 앱 메인 컬러를 파란색에서 보라색으로 바꾸자"고 하면, 이 파일 한 줄만 수정하면 회원가입의 모든 페이지가 단 1초 만에 일관성 있게 바뀝니다.
- `lib/theme/app_text_styles.dart`: `AppTextStyles.h1`, `AppTextStyles.buttonText`와 같이 화면 상단 제목, 본문, 하단 버튼 등 반복되는 폰트 세팅을 묶었습니다. 

## 2. 진척도 게이지 바 부품화(Widget Component)
매 화면마다 40여 줄씩 복사/붙여넣기 되어 있어 파일 용량을 길어지게 만들었던 1번~3번 동그라미 막대(Stepper)를 `lib/widgets/signup_stepper.dart`의 하나의 UI 부품으로 완전히 분리해냈습니다.
덕분에 회원가입의 모든 화면 코드가 엄청나게 짧고 깔끔하게(`const SignupStepper(currentStep: n)`) 한 줄로 다이어트되었습니다.

## 3. 안정성 테스팅
- 기존 스크린들(`signup_screen`, `signup_step2`, `signup_step3`)의 하드코딩된 값들을 모두 날리고 테마 파일을 불러오도록 싹 교체했습니다.
- 전체 스캔 테스트(`flutter analyze`) 결과 **구문 에러 0개 (No issues found!)** 로 완벽하게 안착된 것을 확인했습니다.

> [!TIP]
> 핫 리로드(F5)를 수행해 보시면 겉으로 보이는 디자인은 1픽셀도 달라지지 않았을 겁니다. **이것이 바로 성공적인 리팩토링(코드를 더 깨끗하게 만드는 작업)의 증거입니다!** 
> 겉은 똑같이 예쁘게 작동하지만, 내부는 훨씬 탄탄하고 우아한 코드 구조로 진화했습니다!
