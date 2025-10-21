# whattodo

**Flutter 멀티플랫폼 할 일 관리 / 유틸리티 앱 템플릿**  
> 포트폴리오용으로 제작된 Flutter 프로젝트로, 하나의 코드베이스로 Android, iOS, Web, Desktop을 모두 지원합니다.  
> 단순한 할 일 앱에서 시작해, 다양한 개인 유틸리티 기능으로 확장 가능한 구조를 목표로 합니다.

---

## 🚀 프로젝트 개요

- **프로젝트 이름:** `whattodo`  
- **요약:** Flutter를 활용해 개발한 멀티플랫폼 기반의 Todo/유틸리티 앱 템플릿  
- **목적:**  
  - Flutter 멀티플랫폼 빌드 경험 확보  
  - 포트폴리오용 클린 아키텍처 구조 구현  
  - 단일 코드베이스로 모바일·웹·데스크톱 모두 지원  

---

## 🧩 핵심 기능

| 구분 | 설명 |
|------|------|
| **플랫폼 지원** | Android / iOS / Web / macOS / Windows / Linux |
| **네트워크 연동** | `http` 패키지를 활용한 외부 API 호출 기능 |
| **에셋 관리** | `/assets/images` 폴더 내 이미지 리소스 활용 |
| **구현 기능 예시** | 할 일 생성·수정·삭제(CRUD), 로컬 저장, 알림 예약, 테마 모드 지원 등 |
| **빌드 구성** | 각 플랫폼별 폴더 구조(Android, iOS, macOS 등) 포함 |

---

## 👤 역할 (`hongsh2003`)

- **주요 역할:**  
  전체 설계 및 구현 (UI·로직 포함) / Flutter 프로젝트 구조 설계 / 멀티플랫폼 빌드 환경 설정

- **기여 내용:**  
  - Android·iOS·Web·Desktop 빌드 통합 구조 설계  
  - `http` 기반 외부 API 통신 모듈 개발  
  - 에셋 및 리소스 폴더 구조 정리  
  - UI·UX 와이어프레임 설계 및 구현  

## 👤 역할 (`승원`)

- **주요 역할:**  
  전체 설계 및 구현 (UI·로직 포함) / Flutter 프로젝트 구조 설계 / 멀티플랫폼 빌드 환경 설정

- **기여 내용:**  
  - Android·iOS·Web·Desktop 빌드 통합 구조 설계  
  - `http` 기반 외부 API 통신 모듈 개발  
  - 에셋 및 리소스 폴더 구조 정리  
  - UI·UX 와이어프레임 설계 및 구현  

---

## 🛠 기술 스택

| 항목 | 내용 |
|------|------|
| **언어 / 프레임워크** | Dart / Flutter |
| **Dart SDK** | `^3.9.2` |
| **주요 패키지** | `cupertino_icons: ^1.0.8`, `http: ^1.1.0` |
| **개발 도구** | Flutter CLI, Android Studio, VS Code |
| **특징** | 멀티플랫폼 구성 (모바일 + 웹 + 데스크톱) |

---

## 📂 프로젝트 구조

```plaintext
whattodo/
├── lib/                # 주요 소스코드 (entry: main.dart)
├── assets/
│   └── images/         # 이미지 리소스
├── android/            # Android 빌드 폴더
├── ios/                # iOS 빌드 폴더
├── web/                # 웹 빌드 폴더
├── macos/              # macOS 빌드 폴더
├── windows/            # Windows 빌드 폴더
├── linux/              # Linux 빌드 폴더
├── test/               # 테스트 코드
├── pubspec.yaml        # 의존성 및 에셋 설정
├── analysis_options.yaml
├── .gitignore
└── README.md
```

---

## ⚙️ 설치 및 실행 가이드

1. **환경 준비**
   - Flutter SDK (Dart SDK ≥ 3.9.2)
   - Android SDK / Xcode / Web 환경 등 대상 플랫폼별 도구 설치

2. **저장소 클론**
   ```bash
   git clone https://github.com/sswwdk/EclipseApp.git
   cd EclipseApp
   ```

3. **패키지 설치**
   ```bash
   flutter pub get
   ```

4. **앱 실행**
   - 모바일 / 데스크톱:
     ```bash
     flutter run
     ```
   - 웹(Chrome):
     ```bash
     flutter run -d chrome
     ```

5. **빌드 예시**
   ```bash
   # Android APK
   flutter build apk --release

   # Web 빌드
   flutter build web
   ```

---

## 🧾 주요 설정

**pubspec.yaml 요약**
```yaml
name: whattodo
description: "A new Flutter project."
environment:
  sdk: ^3.9.2
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
assets:
  - assets/images/
```

**분석 규칙**
- `analysis_options.yaml` 포함 (린트/코드 품질 관리)

---

## 🧪 테스트

- 단위 테스트 및 위젯 테스트 실행:
  ```bash
  flutter test
  ```

---

## 💡 향후 개선 계획

- 상태 관리 라이브러리 도입 (Riverpod / Provider / Bloc 등)
- UI/UX 디자인 개선 및 반응형 지원 강화
- E2E / 통합 테스트 추가
- 다국어(Localization) 및 접근성(Accessibility) 개선
- API 기반 할 일 동기화 기능 추가

---

## 💬 포트폴리오 요약

| 항목 | 설명 |
|------|------|
| **Flutter 멀티플랫폼 경험** | Android, iOS, Web, Desktop 환경에서 빌드 및 테스트 경험 |
| **외부 API 연동** | `http` 패키지를 통한 REST API 통신 모듈 구현 |
| **설계 및 구조화 능력** | 에셋·플랫폼·소스코드 구조를 체계적으로 구성 |
| **UI/UX 개발 역량** | Flutter 위젯 구조 및 반응형 레이아웃 구성 능력 |

---

## 📬 연락처

- **GitHub:** [https://github.com/hongsh2003](https://github.com/hongsh2003)  
- **이메일:** *(원하시면 추가)*

---

## 🪪 라이선스

이 프로젝트는 **MIT License** 하에 배포됩니다.  
자유롭게 수정·배포·활용 가능합니다.

---

## 🎨 (선택) 데모 / 스크린샷

```markdown
![앱 실행 화면](assets/images/demo_main.png)
```

> 실제 앱 실행 화면이나 배포 URL을 추가하면 포트폴리오 완성도가 높아집니다.
