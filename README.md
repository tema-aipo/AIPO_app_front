# aipo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Flutter 앱 및 에뮬레이터 실행 가이드

이 문서는 개발 과정에서 **안드로이드 에뮬레이터를 켜고 Flutter 앱을 실행**하는 방법을 요약한 가이드입니다. 

## 1. 터미널 명령어를 사용하는 방법 (CLI 방식)

제가 방금 앱을 띄울 때 사용했던 명령어 방식입니다. 터미널(Terminal) 창을 열고 프로젝트 폴더(`c:\Users\baeki\AIPO`)에서 아래 명령어들을 순서대로 입력합니다.

### 1-1. 설치된 에뮬레이터 목록 확인
현재 컴퓨터에 설치된 가상 기기(Emulator)들의 목록과 ID를 확인합니다.
```bash
flutter emulators
```
> 출력 결과 예시)
> `Pixel_7` • Pixel 7 • Google • android

### 1-2. 에뮬레이터 켜기
확인한 에뮬레이터 ID(예: `Pixel_7`)를 이용해 앱을 띄울 스마트폰 화면을 준비합니다.
```bash
flutter emulators --launch Pixel_7
```
(이 명령어를 치면 백그라운드에서 스마트폰 가상 기기가 팝업 형태로 나타납니다.)

### 1-3. Flutter 앱 실행하기
켜져 있는 에뮬레이터 위에 앱을 설치하고 실행합니다.
```bash
flutter run
```
> [!NOTE]
> `flutter run` 상태일 때 사용 가능한 편리한 단축키:
> - 터미널 창에 `r` 키를 누르면 **핫 리로드(Hot Reload)**가 작동해 1~2초 만에 코드를 갱신합니다.
> - 대문자 `R` 키를 누르면 **핫 리스타트(Hot Restart)**가 작동해 앱을 재시작합니다.
> - `q` 키를 누르면 앱 실행을 종료합니다.

---

## 2. VS Code 화면을 사용하는 방법 (권장 방식) ⭐️

명령어를 매번 치는 것보다 훨씬 간편하고 강력한 방법으로, 이 방법을 **가장 강력하게 추천**합니다.

1. **에뮬레이터 바로 띄우기**: 
   - VS Code 우측 하단을 보시면 `Windows (flutter)` 또는 현재 연결된 기기 이름이 적힌 작은 상태바(Status bar) 버튼이 있습니다.
   - 이 버튼을 클릭하면 위쪽 중앙에 **디바이스 선택 창**이 뜹니다.
   - 여기서 `Pixel 7`과 같은 에뮬레이터를 클릭하시면 스마트폰 화면이 바로 켜집니다!

2. **앱 바로 실행하기 (F5 키)**:
   - 에뮬레이터가 켜진 상태에서 키보드의 `F5` 키를 누르거나, 좌측 메뉴 중 `실행 및 디버그(Run and Debug)` 탭에서 실행 아이콘(▶️)을 누릅니다.
   - 처음에는 약간의 시간이 걸리지만, 백그라운드에서 알아서 빌드를 마치고 앱을 화면에 예쁘게 띄웁니다.

3. **자동 핫 리로드 (저장 시 자동)**:
   - 터미널처럼 `r`을 누르러 갈 필요 없이, 코드를 수정하고 **저장(`Ctrl + S`)하는 순간 알아서 핫 리로드가 동작**하며 앱 화면이 휙휙 바뀝니다!

> [!TIP]
> 백그라운드로 실행 중이던 이전의 제 작업은 VS Code 통합 관리에 방해가 될 수 있어, 이제부터는 개발자님께서 편하게 F5를 눌러 개발하실 수 있도록 백그라운드 작업은 제가 종료해 두도록 하겠습니다.

---

# 로컬 백엔드 서버 실행 가이드 (Windows) 🚀

로컬 환경에서 백엔드 서버를 연동하여 개발을 진행할 때 아래 단계를 통해 서버를 구동할 수 있습니다.

1. **백엔드 프로젝트 루트 폴더로 이동**:
   ```powershell
   cd C:\Users\baeki\AIPO_BE
   ```

2. **서버 실행 명령어 입력**:
   ```powershell
   .\gradlew bootRun
   ```

